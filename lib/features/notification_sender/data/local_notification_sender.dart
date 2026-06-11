import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/core/utils/app_logging.dart';
import 'package:mobile_controller/features/notification_sender/domain/model/app_notification.dart';
import '../domain/i_local_notification_sender.dart';

class NotificationReceiverImpl implements INotificationListener{
  final IConnectionManager _connectionManager;
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  StreamSubscription? _notificationSubscription;

  NotificationReceiverImpl({
    required IConnectionManager connectionManager,
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _connectionManager = connectionManager,
        _methodChannel = methodChannel ?? const MethodChannel('com.example.notification_detection'),
        _eventChannel = eventChannel ?? const EventChannel('com.example.notification_detection/events');


  @override
  Future<void> start() async {
    if (_notificationSubscription != null) return;
    logDebug('Notification Listener', 'Waking up service');

    try {
      final dynamic result = await _methodChannel.invokeMethod('initializeNotificationDetection');
      final bool hasPermission = result ?? false;

      if (!hasPermission) {
        logDebug('Notification Listener', 'Permission missing');
        return;
      }

      _notificationSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) => _handleNotification(Map<String, dynamic>.from(event)),
        onError: (e) => logDebug('Notification Listener', 'Stream error $e'),
        onDone: () => _notificationSubscription = null,
      );
    } catch (e) {
      logDebug('Notification Listener', 'Initialization Failed');
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    try {
      final notification = AppNotification(
        id: DateTime.now().microsecondsSinceEpoch, 
        appName: data['titleText'] ?? 'Unknown Sender',
        title: data['titleText'] ?? '',
        body: data['bodyText'] ?? '',
        timestamp: DateTime.now(),
        colorValue: data['color'] ?? 0, 
        packageName: data['packageName'] ?? 'Unknown',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      _connectionManager.send(
        'notification', 
        'receive', 
        notification.toMap()
      );
      logDebug('Notification Listener', 'Notification Sent');
    } catch (e) {
      logDebug('Notification Listener', 'Error Formatting Payload');
    }
  }

  @override
  Future<void> stop() async {
    if (_notificationSubscription == null) return;

    logDebug('Notification Listener', 'Stopping notification listener in background');
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    
    try {
      await _methodChannel.invokeMethod('dispose');
      logDebug('Notification Listener', 'Native resources cleanly disposed');
    } catch (e) {
      logDebug('Notification Listener', 'Native dispose warning (Safe to ignore if connection drops): $e');
    }
  }
}