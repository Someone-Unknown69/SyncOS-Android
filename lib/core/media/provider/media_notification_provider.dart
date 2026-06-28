// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/media/data/android_media_notification.dart';
import 'package:syncos_android/core/media/domain/i_media_notification.dart';
import 'package:syncos_android/features/media/provider/remote_media_provider.dart';

final mediaNotificationProvider = Provider<IMediaNotification>((ref) {
  final remoteMediaService = ref.read(remoteMediaServiceProvider);
  return AndroidMediaNotification(remoteMediaService);
});
