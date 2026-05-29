import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/storage_service.dart';

// State class to hold theme settings
class ThemeSettings {
  final ThemeMode themeMode;
  final Color seedColor;

  ThemeSettings({required this.themeMode, required this.seedColor});

  ThemeSettings copyWith({ThemeMode? themeMode, Color? seedColor}) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

// Notifier to manage the state
class ThemeNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    final savedModeIndex = StorageService.themeModeIndex;
    final savedColorValue = StorageService.seedColorValue;

    return ThemeSettings(
      themeMode: savedModeIndex != null 
          ? ThemeMode.values[savedModeIndex] 
          : ThemeMode.system,
      seedColor: savedColorValue != null 
          ? Color(savedColorValue) 
          : Colors.blue,
    );
  }

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    StorageService.setThemeModeIndex(mode.index);
  }

  void updateSeedColor(Color color) {
    state = state.copyWith(seedColor: color);
    StorageService.setSeedColorValue(color.value);
  }
}

// Provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeSettings>(() {
  return ThemeNotifier();
});