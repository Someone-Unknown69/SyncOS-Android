// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

class RemoteCommand {
  final String id;
  final String commandName;
  final String commandDescription;
  final String payload; 
  final int colorValue; 
  final bool requiresRoot; 

  RemoteCommand({
    required this.id,
    required this.commandName,
    required this.commandDescription,
    required this.payload,
    required this.colorValue,
    required this.requiresRoot,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'command_name': commandName,
      'command_description': commandDescription,
      'payload': payload,
      'color_value': colorValue,
      'requires_root': requiresRoot ? 1 : 0, 
    };
  }

  factory RemoteCommand.fromMap(Map<String, dynamic> map) {
    return RemoteCommand(
      id: map['id'] as String,
      commandName: map['command_name'] as String,
      commandDescription: map['command_description'] as String,
      payload: map['payload'] as String,
      colorValue: map['color_value'] as int,
      requiresRoot: (map['requires_root'] as int) == 1,
    );
  }
}