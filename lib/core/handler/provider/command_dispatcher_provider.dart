// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/handler/data/command_dispatcher.dart';
import 'package:syncos_android/core/handler/domain/i_command_dispatcher.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/core/utilities/provider/providers.dart';
import 'package:syncos_android/features/music/provider/local_media_sender_provider.dart';

final commandDispatcherProvider = Provider<ICommandDispatcher>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  final ringtoneService = ref.watch(ringtoneServiceProvider);
  final mediaService = ref.watch(mediaServiceProvider);

  return CommandDispatcher(
    connectionManager,
    ringtoneService,
    mediaService
  );
});