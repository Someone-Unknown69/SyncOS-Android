import 'package:flutter/material.dart';
import 'package:mobile_controller/core/config/app_routes.dart';
import 'package:mobile_controller/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppTheme.padding,
          right: AppTheme.padding,
          bottom: AppTheme.padding,
          top: AppTheme.padding * 3, 
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacing * 2),

            _buildSectionHeader(context, 'Connection & Server'),
            _buildSettingsTile(
              icon: Icons.lan_rounded,
              title: 'Server Configuration',
              subtitle: 'Manage IP addresses and port access',
              onTap: () {
                // Handle navigation or modal action
              },
            ),
            _buildSettingsTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Pair New Device',
              subtitle: 'Scan or enter a fresh pairing token',
              onTap: () {
                // Handle re-pairing setup
              },
            ),

            const SizedBox(height: AppTheme.spacing),

            _buildSectionHeader(context, 'Preferences'),
            _buildSettingsTile(
              icon: Icons.palette_rounded,
              title: 'Theme Mode',
              subtitle: 'System default, light, or dark mode',
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.themeMode);
              },
            ),

            const SizedBox(height: AppTheme.spacing),

            _buildSectionHeader(context, 'About'),
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'SyncOS Client',
              subtitle: 'Version 1.0.0',
              onTap: null, // Keep null to make it read-only
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
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
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13),
        ),
        trailing: onTap != null 
            ? const Icon(Icons.chevron_right_rounded, size: 20) 
            : null,
      ),
    );
  }
}