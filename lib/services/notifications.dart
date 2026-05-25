import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'socket_client.dart';

class NotificationReciever {
  static const MethodChannel _methodChannel = MethodChannel('com.example.notification_detection');
  static const EventChannel _eventChannel = EventChannel('com.example.notification_detection/events');

  StreamSubscription? _notificationSubscription;

  Future<void> init() async {
    final bool hasPermisson = await _methodChannel.invokeMethod('initializeNotificationDetection') ?? false;
 
    try {
      if(!hasPermisson) {
        debugPrint('[NotificationReceiver] Permission missing');
        await _methodChannel.invokeMethod('openNotificationSettings');
        return;
      }

      await dispose();

      _notificationSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(event);
            debugPrint('recieved');
            sendNotification(data);
          }
        },
        onError: (error) {
          debugPrint('[NotificationReceiver] Stream error : $error');
        },
      );

      debugPrint('[NotificationReceiver] Notification platform bridge listening successfully');
    } catch (e) {
      debugPrint('[NotificationReceiver] Failed to mount stream platform channel pipeline: $e');
    }
  }

  void sendNotification(Map<String, dynamic> data) {
    try {
      final DateTime timestamp = DateTime.now();
      
      final String appTitle = data['titleText'] ?? 'Unknown Sender';
      final String appBody = data['bodyText'] ?? '';
      final String appSub = data['subText'] ?? '';
      final String pkgName = data['packageName'] ?? 'Unknown Package';

      SocketClient.instance.send(
        'notification', 
        'receive', 
        {
          'app': appTitle,
          'timestamp': timestamp.toIso8601String(),
          'body': appBody,
          'color': null,
          'subText': appSub,
          'packageName': pkgName,
        }
      );
      debugPrint('[NotificationReceiver] Notification sent to server');
    } catch (e) {
      debugPrint('[NotificationReceiver] Error formatting payload: $e');
    }
  }
  
  Future<void> dispose() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (e){
      debugPrint('[NotificationReciever] Error in disposing : $e');
    }
  }
}