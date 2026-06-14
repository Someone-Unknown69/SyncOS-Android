// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:syncos_android/core/handler/domain/i_command_dispatcher.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/features/battery/domain/i_local_battery_sender.dart';
import 'package:syncos_android/features/music/domain/i_local_media_sender.dart';
import 'package:syncos_android/features/notification_sender/domain/i_local_notification_sender.dart';

class ServiceCoordinator {
  final IConnectionManager _connectionManager;
  final IBatteryMonitorService _batteryMonitorService;
  final IMediaService _mediaService;
  final INotificationListener _notificationListener;
  final ICommandDispatcher _commandDispatcher;

  bool running = false;

  StreamSubscription? _connectionSubscription;

  ServiceCoordinator({
    required IConnectionManager connectionManager,
    required IBatteryMonitorService batteryMonitorService,
    required IMediaService mediaService,
    required INotificationListener notificationListener,
    required ICommandDispatcher commandDispatcher,
  })  : _notificationListener = notificationListener,
        _commandDispatcher = commandDispatcher,
        _connectionManager = connectionManager,
        _batteryMonitorService = batteryMonitorService,
        _mediaService = mediaService {
    _init();
  }

  void _init() {
    logDebug('Coordinator', 'Initializing ServiceCoordinator instance');
    _connectionManager.start();

    _connectionSubscription = _connectionManager.connectionStatusStream.listen((status) async {
      logDebug('Coordinator', 'Connection status changed to: ${status.name} and now ($running)');
      if (status == ConnectionStatus.connected) {
        await _startServices();
        running = true;
      } else {
        if(running) {
          await _stopServices();
          running = false;
        }
      }
    });
  }

  Future<void> _startServices() async {
    logDebug('Coordinator', 'Beginning sequential service activation lifecycle');
    
    logDebug('Coordinator', 'Activating Battery Monitor Service [1/4]');
    await _batteryMonitorService.start();
    
    logDebug('Coordinator', 'Activating Media Service [2/4]');
    await _mediaService.start();
    
    logDebug('Coordinator', 'Activating Notification Listener [3/4]');
    await _notificationListener.start();
    
    logDebug('Coordinator', 'Activating Command Dispatcher [4/4]');
    _commandDispatcher.start();
    
    logDebug('Coordinator', 'All background subsystems successfully running');
  }

  Future<void> _stopServices() async {
    logDebug('Coordinator', 'Beginning subsystem termination sequence');
    
    logDebug('Coordinator', 'Hilting Command Dispatcher teardown');
    _commandDispatcher.stop();
    
    logDebug('Coordinator', 'Halting Battery Monitor Service');
    _batteryMonitorService.stop(); 

    logDebug('Coordinator', 'Awaiting concurrent stop for Media and Notification subsystems');
    await Future.wait<void>([
      _mediaService.stop(),
      _notificationListener.stop(),
    ]);
    
    logDebug('Coordinator', 'All background subsystems safely halted');
  }

  void dispose() {
    logDebug('Coordinator', 'Disposing Coordinator and cleaning stream bindings');
    _connectionSubscription?.cancel();
    _stopServices();
  }
}
