// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import '../data/local_media_sender.dart';
import '../domain/i_local_media_sender.dart';

final mediaServiceProvider = Provider<IMediaService>((ref) {
  final connectionManager = ref.read(connectionManagerProvider);
  final service = MediaServiceImpl(connectionManager: connectionManager);
  
  ref.onDispose(() => service.dispose());
  
  return service;
});