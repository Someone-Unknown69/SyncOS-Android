import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/theme/app_theme.dart';
import 'package:mobile_controller/theme/theme_notifier.dart';
import 'widgets/color_picker.dart';

class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Preferences'),
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Appearance'),
            
            // Light / Dark Theme Toggle
            _buildSettingsTile(
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
            _buildSettingsTile(
              icon: Icons.color_lens_rounded,
              title: 'App Theme',
              subtitle: 'Select your preferred accent color',
              onTap: () => _showColorPicker(context, ref),
            ),

            // Font Selection
            _buildSettingsTile(
              icon: Icons.font_download_rounded,
              title: 'App Font',
              subtitle: 'Choose your preferred font family',
              onTap: () => _showFontPicker(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 20),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
      ),
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