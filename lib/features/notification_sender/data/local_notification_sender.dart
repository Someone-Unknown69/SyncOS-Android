import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
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

    try {
      final dynamic result = await _methodChannel.invokeMethod('initializeNotificationDetection');
      final bool hasPermission = result ?? false;

      if (!hasPermission) {
        debugPrint('[NotificationReceiver] Permission missing');
        _methodChannel.invokeMethod('openNotificationSettings');
        return;
      }

      _notificationSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) => _handleNotification(Map<String, dynamic>.from(event)),
        onError: (e) => debugPrint('[NotificationReceiver] Stream error: $e'),
        onDone: () => _notificationSubscription = null,
      );
    } catch (e) {
      debugPrint('[NotificationReceiver] Initialization failed: $e');
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
        colorValue: data['color'] ?? 0, // Ensure you have a default
        packageName: data['packageName'] ?? 'Unknown',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      _connectionManager.send(
        'notification', 
        'receive', 
        notification.toMap()
      );
      debugPrint('[NotificationReceiver] Notification sent to server');
    } catch (e) {
      debugPrint('[NotificationReceiver] Error formatting payload: $e');
    }
  }

  @override
  void stop() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _methodChannel.invokeMethod('dispose').catchError((e) => debugPrint('$e'));
  }

  @override
  Future<void> dispose() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _methodChannel.invokeMethod('dispose').catchError((e) => debugPrint('$e'));
  }
}