import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/config/app_router.dart';
import 'package:mobile_controller/core/config/app_routes.dart';
import 'package:mobile_controller/features/pairing/provider/pairing_notifier.dart';
import 'package:mobile_controller/pages/components/base_page.dart';
import 'package:mobile_controller/pages/components/settings_tile.dart';
import 'package:mobile_controller/pages/home/home_screen.dart';
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


  Future<void> _handleManualConnect() async {
    final ip = _ipController.text;
    final port = int.tryParse(_portController.text) ?? 8080;
    final data = {
      'ip' : ip,
      'port': port,
      'type': 'tcp',
    };

    final success =
        await ref.read(pairingProvider.notifier).pair(data);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pairing failed: Authentication error')),
      );
    }
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

        buildSectionHeader(context, 'Manual Configuration'),
        
        TextField(
          controller: _ipController,
          decoration: InputDecoration(
            labelText: 'Server IP Address',
            hintText: 'e.g., 192.168.1.5',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppTheme.spacing),
        
        TextField(
          controller: _portController,
          decoration: InputDecoration(
            labelText: 'Port Number',
            hintText: 'e.g., 8080',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: AppTheme.spacing * 2),
        

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              await _handleManualConnect();
            },
            child: const Text('Connect to Server'),
          ),
        ),
      ]
    );
  }
}