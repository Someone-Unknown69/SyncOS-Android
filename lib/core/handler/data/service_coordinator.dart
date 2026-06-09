import 'dart:async';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/features/battery/domain/i_local_battery_sender.dart';
import 'package:mobile_controller/features/music/domain/i_local_media_sender.dart';
import 'package:mobile_controller/features/notification_sender/domain/i_local_notification_sender.dart';
import 'package:mobile_controller/core/handler/data/command_dispatcher.dart';

class ServiceCoordinator {
  final IConnectionManager _connectionManager;
  final IBatteryMonitorService _batteryMonitorService;
  final IMediaService _mediaService;
  final INotificationListener _notificationListener;
  final CommandDispatcher _commandDispatcher;

  StreamSubscription? _connectionSubscription;

  ServiceCoordinator({
    required IConnectionManager connectionManager,
    required IBatteryMonitorService batteryMonitorService,
    required IMediaService mediaService,
    required INotificationListener notificationListener,
    required CommandDispatcher commandDispatcher,
  })  : _notificationListener = notificationListener,
        _commandDispatcher = commandDispatcher,
        _connectionManager = connectionManager,
        _batteryMonitorService = batteryMonitorService,
        _mediaService = mediaService {
    _init();
  }

  void _init() {
    _connectionManager.start();

    _connectionSubscription = _connectionManager.connectionStatusStream.listen((status) async {
      if (status == ConnectionStatus.connected) {
        await _startServices();
      } else {
        _stopServices();
      }
    });
  }

  Future<void> _startServices() async {
    await _batteryMonitorService.start();
    await _mediaService.start();
    await _notificationListener.start();
    _commandDispatcher.start();
  }

  void _stopServices() {
    _batteryMonitorService.stop();
    _mediaService.stop();
    _notificationListener.dispose();
    _commandDispatcher.stop();
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _stopServices();
  }
}
