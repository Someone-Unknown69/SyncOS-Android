import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/handler/data/command_dispatcher.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/features/music/provider/local_media_sender_provider.dart';
import 'package:mobile_controller/features/file_transfer/provider/file_transfer_provider.dart';

final commandDispatcherProvider = Provider<CommandDispatcher>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  final mediaService = ref.watch(mediaServiceProvider);
  final fileTransferService = ref.read(fileTransferServiceProvider);
  
  return CommandDispatcher(
    ref,
    connectionManager,
    mediaService,
    fileTransferService,
  );
});