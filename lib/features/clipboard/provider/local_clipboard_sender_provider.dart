import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/features/clipboard/data/local_clipboard_sender.dart';

final localClipboardSenderProvider = Provider<LocalClipboardSender>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  return LocalClipboardSender(
    connectionManager,
  );
});