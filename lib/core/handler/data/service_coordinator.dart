// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:syncos_android/core/handler/domain/i_command_dispatcher.dart';
import 'package:syncos_android/core/media/domain/i_media_notification.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/features/battery/domain/i_local_battery_sender.dart';
import 'package:syncos_android/features/media/data/local_media_sender.dart';
import 'package:syncos_android/features/media/data/remote_media_service.dart';
import 'package:syncos_android/features/notification_sender/domain/i_local_notification_sender.dart';

class ServiceCoordinator {
  final IConnectionManager _connectionManager;
  final IBatteryMonitorService _batteryMonitorService;
  final LocalMediaSender _mediaService;
  final INotificationListener _notificationListener;
  final ICommandDispatcher _commandDispatcher;
  final RemoteMediaService _remoteMediaService;
  final IMediaNotification _mediaNotification;
  final ServiceInstance _service;

  bool running = false;

  StreamSubscription? _connectionSubscription;

  ServiceCoordinator({
    required IConnectionManager connectionManager,
    required IBatteryMonitorService batteryMonitorService,
    required LocalMediaSender mediaService,
    required INotificationListener notificationListener,
    required ICommandDispatcher commandDispatcher,
    required RemoteMediaService remoteMediaService,
    required IMediaNotification mediaNotification,
    required ServiceInstance service,
  }) : _notificationListener = notificationListener,
       _commandDispatcher = commandDispatcher,
       _connectionManager = connectionManager,
       _batteryMonitorService = batteryMonitorService,
       _remoteMediaService = remoteMediaService,
       _mediaNotification = mediaNotification,
       _service = service,
       _mediaService = mediaService {
    _init();
  }

  void _init() {
    logDebug('Coordinator', 'Initializing ServiceCoordinator instance');
    _connectionManager.start();

    _connectionSubscription = _connectionManager.connectionStatusStream.listen((
      status,
    ) async {
      logDebug(
        'Coordinator',
        'Connection status changed to: ${status.name} and now ($running)',
      );
      if (status == ConnectionStatus.connected) {
        await _startServices();
        running = true;
      } else {
        if (running) {
          await _stopServices();
          running = false;
        }
      }
    });
  }

  Future<void> _startServices() async {
    logDebug(
      'Coordinator',
      'Beginning sequential service activation lifecycle',
    );

    logDebug('Coordinator', 'Activating Battery Monitor Service');
    await _batteryMonitorService.start();

    logDebug('Coordinator', 'Activating Media Service');
    await _mediaService.start();

    logDebug('Coordinator', 'Activating Notification Listener');
    await _notificationListener.start();

    logDebug('Coordinator', 'Activating remote media service');
    await _remoteMediaService.start(backgroundService: _service);

    logDebug('Coordinator', 'Activating Media Service');
    await _mediaNotification.start();

    logDebug('Coordinator', 'Activating Command Dispatcher');
    _commandDispatcher.start();

    logDebug('Coordinator', 'All background subsystems successfully running');
  }

  Future<void> _stopServices() async {
    logDebug(
      'Coordinator',
      'Beginning strict sequential subsystem termination sequence',
    );

    logDebug('Coordinator', 'Halting Command Dispatcher');
    _commandDispatcher.stop();

    logDebug('Coordinator', 'Halting Media Notification Service');
    await _mediaNotification.stop();

    logDebug('Coordinator', 'Halting Remote Media Service Stream Channels');
    await _remoteMediaService.stop();

    logDebug('Coordinator', 'Halting Media and Notification subsystems');
    await _mediaService.stop();
    await _notificationListener.stop();

    logDebug('Coordinator', 'Halting Battery Monitor Service');
    _batteryMonitorService.stop();

    logDebug('Coordinator', 'All background subsystems safely halted');
  }

  void dispose() {
    logDebug(
      'Coordinator',
      'Disposing Coordinator and cleaning stream bindings',
    );
    _connectionSubscription?.cancel();
    _stopServices();
  }
}
