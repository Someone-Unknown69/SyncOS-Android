// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import '../domain/i_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServiceImpl implements INotificationService {

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');

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
      icon: '@mipmap/launcher_icon',

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
  Future<void> showErrorNotification({
    required int id, 
    required String title, 
    required String error
  }) async {
    await showNotification(
      id: id,
      title: title,
      body: error,
      urgency: 3,
      icon: '@mipmap/launcher_icon',
    );
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    String? body,
    int urgency = 1,
    String icon = '@mipmap/launcher_icon',
  }) async {
    final androidImportance = switch (urgency) {
      0 => Importance.low,
      1 => Importance.defaultImportance,
      2 => Importance.high,
      3 => Importance.max,
      _ => Importance.defaultImportance,
    };

    final androidPriority = switch (urgency) {
      0 => Priority.low,
      1 => Priority.defaultPriority,
      2 => Priority.high,
      3 => Priority.max,
      _ => Priority.defaultPriority,
    };

    final androidDetails = AndroidNotificationDetails(
      'normal_channel',
      'SyncOS',
      channelDescription: 'SyncOS',
      importance: androidImportance,
      priority: androidPriority,
      icon: icon,
      ongoing: false,
      autoCancel: true,
    );

    await _plugin.show(
      id: id,
      title: title,
      body : body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> showTestNotification() async {
    await showNotification(
      id: 100,
      title: 'Ladis',
      body: 'Ladis Washerum',
      urgency: 1,
    );
  }

  @override
  Future<void> dismissNotification(int id) async {
    await _plugin.cancel(id: id);
  }
}