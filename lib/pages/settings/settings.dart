import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/config/app_router.dart';
import 'package:mobile_controller/core/config/app_routes.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/features/pairing/provider/pairing_notifier.dart';
import 'package:mobile_controller/pages/components/base_page.dart';
import 'package:mobile_controller/pages/components/popup_dialog.dart';
import 'package:mobile_controller/theme/app_theme.dart';
import '../components/settings_tile.dart';

final _connectionStatusStreamProvider = StreamProvider<ConnectionStatus>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  return connectionManager.connectionStatusStream;
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage(
      title: 'Settings', 
      showBackButton: false,
      children: [
        buildSectionHeader(context, 'Connection & Server'),
        buildSettingsTile(
          icon: Icons.lan_rounded,
          title: 'Connection Details',
          subtitle: 'Display server IP and Port',
          onTap: () {
            AppRouter.pushRoute(context, AppRoutes.connectionDetails);
          },
        ),

        buildSettingsTile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Pair New Device',
          subtitle: ref.watch(_connectionStatusStreamProvider).maybeWhen(
            data: (status) => status == ConnectionStatus.connected
                ? 'Device is connected. Unpair first to pair a new device.'
                : 'Scan or enter IP and port',
            orElse: () => 'Scan or enter IP and port',
          ),
          onTap: () async {
            final connectionManager = ref.read(connectionManagerProvider);
            final isConnected = connectionManager.status == ConnectionStatus.connected;

            if (isConnected) {
              final confirmed = await showAppPopupDialog(
                context,
                title: 'Unpair Device',
                subtitle: 'This will disconnect from the server and remove saved pairing data.',
                primaryButtonLabel: 'Unpair',
                secondaryButtonLabel: 'Cancel',
                onPrimaryPressed: () async {
                  final success = await ref.read(pairingProvider.notifier).unpairWithServer();
                  debugPrint("Initiating unpair");
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device unpaired successfully.')),
                    );
                  }
                },
              );

              if (confirmed == true && context.mounted) {
                AppRouter.pushRoute(context, AppRoutes.setupScreen);
              }
            } else {
              // This shall not be case anytime, but if it is then check the code 
              // There must be something fishy
              AppRouter.pushRoute(context, AppRoutes.setupScreen);
            }
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