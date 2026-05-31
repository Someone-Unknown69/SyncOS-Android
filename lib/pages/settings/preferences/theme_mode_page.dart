import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/pages/components/base_page.dart';
import 'package:mobile_controller/theme/provider/theme_provider.dart';
import 'widgets/color_picker.dart';
import '../../components/settings_tile.dart';

class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return BasePage(
      title: 'Preferences', 
      showBackButton: true,
      children: [
        buildSectionHeader(context, 'Appearance'),
            
        // Light / Dark Theme Toggle
        buildSettingsTile(
          icon: Icons.dark_mode_rounded,
          title: 'Theme Mode',
          subtitle: 'Switch between light and dark mode',
          trailing: Switch(
            value: theme.brightness == Brightness.dark,
            onChanged: (bool value) {
              ref.read(themeProvider.notifier).updateThemeMode(
                value ? ThemeMode.dark : ThemeMode.light
              );
            },
          ),
        ),

        // Theme Color Selection
        buildSettingsTile(
          icon: Icons.color_lens_rounded,
          title: 'App Theme',
          subtitle: 'Select your preferred accent color',
          onTap: () => _showColorPicker(context, ref),
        ),

        // Font Selection
        buildSettingsTile(
          icon: Icons.font_download_rounded,
          title: 'App Font',
          subtitle: 'Choose your preferred font family',
          onTap: () => _showFontPicker(context),
        ),

      ]
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: HorizontalColorPicker(
          selectedColor: ref.watch(themeProvider).seedColor,
          onColorSelected: (color) {
            ref.read(themeProvider.notifier).updateSeedColor(color);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // Placeholder methods for selection logic
  void _showFontPicker(BuildContext context) { /* Show Modal Bottom Sheet */ }
}