import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/features/run_command/models/remote_command.dart';

class RemoteCommandSender {
  final IConnectionManager _connectionManager;

  RemoteCommandSender(this._connectionManager);

  void sendRemoteCommand(RemoteCommand command) {
    _connectionManager.send(
      'remote_command', 
      'execute', 
      {
        'command' : command.payload.toString(),
        'isRoot' : command.requiresRoot,
      }
    );
  }
}