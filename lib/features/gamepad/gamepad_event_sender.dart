// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/foundation.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';

class USBControllerService {
  final IConnectionManager _connectionManager;

  USBControllerService(this._connectionManager);

  final Map<String, bool> _dpadState = {
    'DPAD_UP': false,
    'DPAD_DOWN': false,
    'DPAD_LEFT': false,
    'DPAD_RIGHT': false,
  };

  double currentL2 = 0.0;
  double currentR2 = 0.0;

  bool isPressed(String key) => _dpadState[key] ?? false;

  void setPressedState(String key, bool isPressed) {
    if (_dpadState.containsKey(key)) {
      _dpadState[key] = isPressed;
    }
  }

  void sendEvent(String action, Map<String, dynamic> args) {
    if (action == 'triggers') {
      currentL2 = (args['l2'] as num).toDouble();
      currentR2 = (args['r2'] as num).toDouble();
    }
    
    debugPrint("[Gamepad] Controller $action: $args");
    _connectionManager.send("controller", action, args);
  }

  void sendAnalog(String analog, double x, double y) {
    sendEvent(analog, {'x': x, 'y': y});
  }
}