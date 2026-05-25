import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();

class NotificationLocal {
    Future<void> initNotif() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotif.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {

      }
    );

    const channel = AndroidNotificationChannel(
      'test_notif', // ID
      'SyncOS',     // Name shown in system settings
      importance: Importance.low,
    );

    await localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }


  Future<void> displayNotif({
    required int id,
    required String title,
    required String body
  }) async {
    final androidDetails =  AndroidNotificationDetails(
      'test_notif',
      'SyncOS',
      channelDescription: 'random shi',
      importance: Importance.defaultImportance,
    );

    await localNotif.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails)
    );

  }

}