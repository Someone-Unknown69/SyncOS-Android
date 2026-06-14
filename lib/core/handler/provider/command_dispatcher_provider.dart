import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/handler/data/command_dispatcher.dart';
import 'package:mobile_controller/core/handler/domain/i_command_dispatcher.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/core/utilities/provider/providers.dart';
import 'package:mobile_controller/features/music/provider/local_media_sender_provider.dart';

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