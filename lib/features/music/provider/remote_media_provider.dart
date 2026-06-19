// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/features/music/data/remote_media_service.dart';
import 'package:syncos_android/features/music/domain/models/media_info.dart';

final remoteMediaServiceProvider = Provider<RemoteMediaService>((ref) {
  final connectionManager = ref.read(connectionManagerProvider);

  final service = RemoteMediaService(connectionManager);
  ref.onDispose(() => service.stop());

  return service;
});

final remoteMediaStreamProvider = StreamProvider<MediaInfo>((ref) {
  final service = ref.read(remoteMediaServiceProvider);
  return service.mediaUpdates;
});
