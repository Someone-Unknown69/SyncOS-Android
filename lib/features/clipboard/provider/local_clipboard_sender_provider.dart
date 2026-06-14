// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/features/clipboard/data/local_clipboard_sender.dart';

final localClipboardSenderProvider = Provider<LocalClipboardSender>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  return LocalClipboardSender(
    connectionManager,
  );
});