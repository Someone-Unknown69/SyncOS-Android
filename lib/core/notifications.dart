import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../theme/app_theme.dart';

final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();

class ProgressNotification {
  Future<void> initNotif() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotif.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {

      }
    );

    const channel = AndroidNotificationChannel(
      'basic_channel', // ID
      'Reminders',     // Name shown in system settings
      importance: Importance.high,
    );

    await localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> displayNotif({
    required int id,
    required String title,
    required String body,
    int progress = 0,
    bool isOngoing = true, 
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'transfer_channel',
      'File Transfer',
      channelDescription: 'Progress of SyncOS file transfers',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      ongoing: isOngoing, // Dynamic status
      autoCancel: !isOngoing, // Allows the notification to disappear when clicked after finishing
      
      actions: isOngoing ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'cancel_transfer',
          'CANCEL',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ] : null, // Remove cancel button when transfer is done
    );

    await localNotif.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails)
    );
  }

  Future<void> showErrorNotif({
    required int id,
    required String fileName,
    String error = "Transfer failed or connection lost",
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'transfer_channel',
      'File Transfer',
      channelDescription: 'Progress of SyncOS file transfers',
      importance: Importance.high, // Higher importance so the user notices the failure
      priority: Priority.high,
      showProgress: false,         // Hide the progress bar on error
      ongoing: false,              // Allow user to swipe it away
      autoCancel: true,            // Dismiss when tapped
      color: AppTheme.errorColor,         // RED !!!! RED !!!!!
      icon: '@mipmap/ic_launcher',
    );

    await localNotif.show(
      id: id,
      title: 'Transfer Failed',
      body: '$fileName: $error',
      notificationDetails: NotificationDetails(android: androidDetails)
    );
  }
}

