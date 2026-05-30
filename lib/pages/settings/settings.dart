import 'package:flutter/material.dart';
import 'package:mobile_controller/core/config/app_router.dart';
import 'package:mobile_controller/core/config/app_routes.dart';
import 'package:mobile_controller/pages/components/base_page.dart';
import 'package:mobile_controller/theme/app_theme.dart';
import '../components/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return BasePage(
      title: 'Settings', 
      showBackButton: false,
      children: [
        buildSectionHeader(context, 'Connection & Server'),
        buildSettingsTile(
          icon: Icons.lan_rounded,
          title: 'Device Configuration',
          subtitle: 'Manage IP addresses and port access',
          onTap: () {
            // Handle navigation or modal action
          },
        ),
        buildSettingsTile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Pair New Device',
          subtitle: 'Scan or enter IP and port',
          onTap: () {
            // Handle re-pairing setup
          },
        ),

        const SizedBox(height: AppTheme.spacing),

        buildSectionHeader(context, 'Preferences'),
        buildSettingsTile(
          icon: Icons.palette_rounded,
          title: 'Theme Mode',
          subtitle: 'System default, light, or dark mode',
          onTap: () {
            AppRouter.pushRoute(context, AppRoutes.themeMode);
          },
        ),

        const SizedBox(height: AppTheme.spacing),

        buildSectionHeader(context, 'About'),
        buildSettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'SyncOS',
          subtitle: 'Version 1.0.0',
          onTap: null,
        ),
      ]
    );
  }
}