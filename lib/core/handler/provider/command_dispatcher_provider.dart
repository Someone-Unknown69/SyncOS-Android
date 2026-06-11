import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/handler/data/command_dispatcher.dart';
import 'package:mobile_controller/core/handler/domain/i_command_dispatcher.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';

final commandDispatcherProvider = Provider<ICommandDispatcher>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  
  return CommandDispatcher(
    connectionManager,
  );
});