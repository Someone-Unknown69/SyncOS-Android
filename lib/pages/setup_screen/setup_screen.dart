import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/config/app_router.dart';
import 'package:mobile_controller/core/config/app_routes.dart';
import 'package:mobile_controller/pages/components/base_page.dart';
import 'package:mobile_controller/pages/components/settings_tile.dart';
import 'package:mobile_controller/theme/app_theme.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Setup', 
      showBackButton: false,
      children: [
        buildSectionHeader(context, 'Connect to device'),

        buildSettingsTile(
          icon: Icons.qr_code_rounded, 
          title: 'Scan QR Code',
          subtitle: 'Automatically configure connection details',
          onTap: () {
            AppRouter.pushRoute(context, AppRoutes.pairingScreen);
          },
        ),

        const SizedBox(height: AppTheme.spacing * 2),
      
        buildSectionHeader(context, 'Enable Permissions'),

        // buildSettingsTile(
        //   icon: Icons.notifications_active_rounded, 
        //   title: 'Notification Access',
        //   subtitle: 'Receive device notifications on Laptop/PC',
        //   trailing: Switch(
        //     value: ,
        //     onChanged: (bool value) {
              
        //     },
        //   ),
        // ),

        // const SizedBox(height: AppTheme.spacing / 2),
      
        // buildSettingsTile(
        //   icon: Icons.storage_rounded, 
        //   title: 'Storage Access',
        //   subtitle: 'Send and receive files remotely',
        //   trailing: Switch(
        //     value: ,
        //     onChanged: (bool value) {
              
        //     },
        //   ),
        // ),

      ]
    );
  }
}