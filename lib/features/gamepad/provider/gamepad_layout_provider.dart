// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/storage/provider/storage_service_provider.dart';
import 'package:syncos_android/features/gamepad/domain/gamepad_layout.dart';

final gamepadLayoutProvider = NotifierProvider<GamepadLayoutNotifier, GamepadLayout>(() {
  return GamepadLayoutNotifier();
});

class GamepadLayoutNotifier extends Notifier<GamepadLayout> {
  @override
  GamepadLayout build() {
    _loadLayout();
    return GamepadLayout.defaultLayout;
  }

  Future<void> _loadLayout() async {
    final storage = ref.read(storageServiceProvider);
    final savedLayout = await storage.getGamepadLayout();
    if (savedLayout != null) {
      state = savedLayout;
    }
  }

  Future<void> updateElement(GamepadElementConfig element) async {
    final newElements = Map<String, GamepadElementConfig>.from(state.elements);
    newElements[element.id] = element;
    
    state = state.copyWith(elements: newElements);
    
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadLayout(state);
  }

  Future<void> resetToDefault() async {
    state = GamepadLayout.defaultLayout;
    final storage = ref.read(storageServiceProvider);
    await storage.setGamepadLayout(state);
  }
}
