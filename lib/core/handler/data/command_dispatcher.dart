// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'dart:convert';
import 'package:syncos_android/core/background/background_event_bus.dart';
import 'package:syncos_android/core/handler/domain/i_command_dispatcher.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/utilities/domain/i_ringtone_service.dart';
import 'package:syncos_android/features/music/domain/i_local_media_sender.dart';

class CommandDispatcher implements ICommandDispatcher {
  final IConnectionManager _connectionManager;

  // Services that strictly run in background and have no intention to use UI
  final IRingtoneService _ringtoneService;
  final IMediaService _mediaService;            // Only for control commands

  StreamSubscription<String>? _rawMessageSubscription;
  bool _isStarted = false;

  CommandDispatcher(
    this._connectionManager,
    this._ringtoneService,
    this._mediaService,
  ) {
    logDebug('Command Dispatcher', 'Initialized');
  }

  @override
  void start() {
    if (_isStarted) return;
    _isStarted = true;
    logDebug('Command Dispatcher', 'Service started and listening for network messages');

    _rawMessageSubscription = _connectionManager.rawMessageStream.listen((rawMessage) {
      try {
        final Map<String, dynamic> data = jsonDecode(rawMessage);
        logDebug('Command Dispatcher', 'Recieved : $data');
        
        // Entry point for background running services
        _handleOperation(data);

        // Entry point for foreground UI updates
        BackgroundEventBus.emit('update_ui_event', {
          'operation': data['op'],
          'action': data['action'],
          'args': data['args'],
        });
      } catch (e) {
        logDebug('Command Dispatcher', 'Failed to process message: $e');
      }
    });
  }

  void _handleOperation(Map<String, dynamic> data) {
    final operation = data['op'];
    final action = data['action'];
    final args = data['args'] as Map<String, dynamic>;

    switch (operation) {
      case 'ring_device':
        _ringtoneService.ringDevice(data: args);
        break;
      case 'music':
        if (action == 'control') {
          _mediaService.sendControlCommand(args);
        }
        break;
      default:
        logDebug('Command Dispatcher', 'Not a background service command');
    }
  }

  @override
  void stop() {
    logDebug('Command Dispatcher', 'Stopping listener');
    _rawMessageSubscription?.cancel();
    _rawMessageSubscription = null;
    _isStarted = false;
  }
}