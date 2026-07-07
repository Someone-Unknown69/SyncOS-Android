// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/gamepad/provider/gamepad_settings_provider.dart';
import 'package:syncos_android/pages/components/base_page.dart';
import 'package:syncos_android/pages/components/setting_components.dart';
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
        const SectionHeader(title: 'Haptic Feedback'),
        SettingsTile(
          icon: Icons.vibration_rounded,
          title: 'Haptics Feedback',
          subtitle: 'Vibrate on button press',
          trailing: Switch(
            value: settings.enableHaptics,
            onChanged: (value) {
              notifier.updateHaptics(value);
            },
          ),
        ),

        const SectionHeader(title: 'Control Style'),
        SettingsSliderSection(
          items: [
            SliderItem(
              icon: Icons.opacity_rounded,
              title: 'Button Opacity',
              value: settings.buttonOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) => notifier.updateButtonOpacity(value),
            ),
          ],
        ),

        const SectionHeader(title: 'Analog Sticks'),
        SettingsSliderSection(
          items: [
            SliderItem(
              icon: Icons.speed_rounded,
              title: 'Stick Sensitivity',
              value: settings.stickSensitivity,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              valueLabelBuilder: (val) => '${val.toStringAsFixed(1)}x',
              onChanged: (value) => notifier.updateStickSensitivity(value),
            ),
            SliderItem(
              icon: Icons.blur_circular_rounded,
              title: 'Stick Deadzone',
              value: settings.stickDeadzone,
              min: 0.0,
              max: 0.5,
              divisions: 10,
              onChanged: (value) => notifier.updateStickDeadzone(value),
            ),
          ],
        ),

        const SectionHeader(title: 'Performance'),
        SettingsDropdownSection<int>(
          icon: Icons.network_ping,
          title: 'Transmission Frequency',
          subtitle: 'Rate of sending updates',
          value: settings.transmissionRateHz,
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

        const SizedBox(height: AppTheme.spacing),
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
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
