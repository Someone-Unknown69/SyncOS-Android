// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/storage/provider/storage_service_provider.dart';
import 'package:syncos_android/features/gamepad/domain/gamepad_settings.dart';

final gamepadSettingsProvider = NotifierProvider<GamepadSettingsNotifier, GamepadSettings>(() {
  return GamepadSettingsNotifier();
});

class GamepadSettingsNotifier extends Notifier<GamepadSettings> {
  @override
  GamepadSettings build() {
    _loadSettings();
    return const GamepadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    final savedSettings = await storage.getGamepadSettings();
    if (savedSettings != null) {
      state = savedSettings;
    }
  }

  Future<void> updateHaptics(bool enableHaptics) async {
    state = state.copyWith(enableHaptics: enableHaptics);
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadSettings(state);
  }

  Future<void> updateButtonOpacity(double opacity) async {
    state = state.copyWith(buttonOpacity: opacity);
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadSettings(state);
  }

  Future<void> updateStickSensitivity(double sensitivity) async {
    state = state.copyWith(stickSensitivity: sensitivity);
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadSettings(state);
  }

  Future<void> updateStickDeadzone(double deadzone) async {
    state = state.copyWith(stickDeadzone: deadzone);
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadSettings(state);
  }

  Future<void> updateTransmissionRateHz(int rateHz) async {
    state = state.copyWith(transmissionRateHz: rateHz);
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadSettings(state);
  }

  Future<void> resetToDefault() async {
    state = const GamepadSettings();
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadSettings(state);
  }
}
