// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/gamepad/provider/gamepad_settings_provider.dart';
import 'package:syncos_android/pages/components/base_page.dart';
import 'package:syncos_android/pages/components/settings_tile.dart';
import 'package:syncos_android/theme/app_theme.dart';

class GamepadSettingsPage extends ConsumerWidget {
  const GamepadSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gamepadSettingsProvider);
    final notifier = ref.read(gamepadSettingsProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BasePage(
      title: 'Gamepad Settings',
      showBackButton: true,
      children: [
        buildSectionHeader(context, 'Haptic Feedback'),
        buildSettingsTile(
          icon: Icons.vibration_rounded,
          title: 'Vibration & Haptics',
          subtitle: 'Vibrate on button press and stick edge',
          trailing: Switch(
            value: settings.enableHaptics,
            onChanged: (value) {
              notifier.updateHaptics(value);
            },
          ),
        ),

        buildSectionHeader(context, 'Control Style'),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.opacity_rounded, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'Button Opacity',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(settings.buttonOpacity * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.buttonOpacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) {
                    notifier.updateButtonOpacity(value);
                  },
                ),
              ],
            ),
          ),
        ),

        buildSectionHeader(context, 'Analog Sticks'),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stick Sensitivity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed_rounded, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'Stick Sensitivity',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${settings.stickSensitivity.toStringAsFixed(1)}x',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.stickSensitivity,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    notifier.updateStickSensitivity(value);
                  },
                ),
                const Divider(height: 24),
                // Stick Deadzone
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.blur_circular_rounded, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'Stick Deadzone',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(settings.stickDeadzone * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.stickDeadzone,
                  min: 0.0,
                  max: 0.5,
                  divisions: 10,
                  onChanged: (value) {
                    notifier.updateStickDeadzone(value);
                  },
                ),
              ],
            ),
          ),
        ),

        buildSectionHeader(context, 'Performance'),
        buildSettingsTile(
          icon: Icons.speed_rounded,
          title: 'Transmission Frequency',
          subtitle: 'Update rate of network state packets',
          trailing: DropdownButton<int>(
            value: settings.transmissionRateHz,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            items: const [
              DropdownMenuItem(value: 30, child: Text('30 Hz (Eco)')),
              DropdownMenuItem(value: 60, child: Text('60 Hz (Std)')),
              DropdownMenuItem(value: 120, child: Text('120 Hz (Perf)')),
            ],
            onChanged: (value) {
              if (value != null) {
                notifier.updateTransmissionRateHz(value);
              }
            },
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () {
              notifier.resetToDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to default')),
              );
            },
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset to Defaults'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
