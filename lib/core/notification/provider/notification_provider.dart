// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/notification/data/android_media_notification.dart';
import 'package:syncos_android/core/notification/domain/i_media_notification.dart';
import 'package:syncos_android/features/music/provider/remote_media_provider.dart';
import '../domain/i_notification_service.dart';
import '../data/notification_service_impl.dart';

/// Notification service used throughout the app
final notificationServiceProvider = Provider<INotificationService>((ref) {
  return NotificationServiceImpl();
});

final mediaNotificationProvider = Provider<IMediaNotification>((ref) {
  final remoteMediaService = ref.read(remoteMediaServiceProvider);
  return AndroidMediaNotification(remoteMediaService);
});
