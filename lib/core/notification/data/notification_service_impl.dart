import '../domain/i_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../theme/app_theme.dart';

class NotificationServiceImpl implements INotificationService {

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
      }
    );

    // Channel for progress updates (file transfer etc.)
    const progressChannel = AndroidNotificationChannel(
      'progress_channel', 'File Transfers',
      importance: Importance.low,
      playSound: false,
      enableLights: false,
    );

    // channel for alert notifications
    const alertChannel = AndroidNotificationChannel(
      'alert_channel', 'SyncOS Alerts',
      importance: Importance.high,
    );

    // channel for normal notifications
    const normalChannel = AndroidNotificationChannel(
      'normal_channel', 'SyncOS',
      importance: Importance.defaultImportance,
    );

    final platform = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(progressChannel);
    await platform?.createNotificationChannel(alertChannel);
    await platform?.createNotificationChannel(normalChannel);
  }

  @override
  Future<void> showTransferProgress({
    required int id, 
    required String title, 
    required String body,
    required int progress,
    bool isOngoing = true
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'progress_channel',
      'File Transfers',
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

    _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> showTransferError({
    required int id, 
    required String title, 
    required String error
  }) async {
    String error = "Transfer failed or connection lost";

    final androidDetails = AndroidNotificationDetails(
      'alert_channel',
      'SyncOS Alerts',
      channelDescription: 'Progress of SyncOS file transfers',
      importance: Importance.high, // Higher importance so the user notices the failure
      priority: Priority.high,
      showProgress: false,         // Hide the progress bar on error
      ongoing: false,              // Allow user to swipe it away
      autoCancel: true,            // Dismiss when tapped
      color: AppTheme.errorColor,         // RED !!!! RED !!!!!
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      id: id,
      title: title,
      body: error,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> showTestNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails =  AndroidNotificationDetails(
      'normal_channel',
      'SyncOS',
      channelDescription: 'random shi',
      importance: Importance.defaultImportance,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> dismissNotification(int id) async {
    await _plugin.cancel(id: id);
  }
}