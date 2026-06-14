// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/features/run_command/models/remote_command.dart';

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