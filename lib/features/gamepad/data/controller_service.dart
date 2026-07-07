// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/network/domain/connection_config.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/network/domain/i_controller_transfer_service.dart';
import 'package:syncos_android/core/storage/data/storage_service.dart';
import 'package:syncos_android/features/gamepad/domain/i_gamepad_state.dart';
import 'package:syncos_android/features/gamepad/domain/gamepad_settings.dart';

class ControllerService {
  final IControllerTransferService _transferService;
  final IGamepadState _gamepadState;
  final StorageService _storageService;
  final IConnectionManager _connectionManager;

  // flag to manage the lifecycle of transmission loop
  bool _isTransmitting = false;

  ControllerService(
    this._transferService,
    this._gamepadState,
    this._storageService,
    this._connectionManager,
  );

  Future<void> start() async {
    ConnectionConfig? config = await _storageService.getConnectionConfig();
    logDebug('ControllerService', '${config?.toJson()}');
    
    if (config == null) {
      logDebug('ControllerService', 'Connection configuration is NULL');
      return;
    }
    
    // TODO : add controller type information in the connection config

    _connectionManager.send('controller', 'start', {});

    await _transferService.connect(config);
    final GamepadSettings? settings = await _storageService.getGamepadSettings();
    final rateHz = settings?.transmissionRateHz ?? 60;
    final tickInterval = Duration(milliseconds: (1000 / rateHz).round());
     _startTransmissionLoop(tickInterval);
  }

  void updateGamepadState() {
    _transferService.sendUpdate(_gamepadState.currState);
  }

  Future<void> stop() async {
    _stopTransmissionLoop();
    _connectionManager.send('controller', 'stop', {});
    await _transferService.disconnect();
  }

  // This sets up a loop which continuously takes snapshots of the current controller state and sends it over the transport channel
  void _startTransmissionLoop(Duration tickInterval) async {
    if (_isTransmitting) {
      return; // Prevent multiple loops from running concurrently
    }
    _isTransmitting = true;

    while (_isTransmitting) {
      final startTime = DateTime.now();

      try {
        updateGamepadState();
      } catch (e) {
        logDebug('ControllerService', 'Error during transmission tick: $e');
      }

      // Calculate execution duration to dynamically compensate for any serialization or I/O jitter
      final executionTime = DateTime.now().difference(startTime);
      final remainingSleepTime = tickInterval - executionTime;

      if (remainingSleepTime.isNegative) {
        await Future.delayed(Duration.zero);
      } else {
        await Future.delayed(remainingSleepTime);
      }
    }
  }

  void _stopTransmissionLoop() {
    _isTransmitting = false;
  }
}
