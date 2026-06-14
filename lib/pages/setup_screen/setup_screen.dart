import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/config/app_router.dart';
import 'package:mobile_controller/core/config/app_routes.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/features/pairing/provider/pairing_notifier.dart';
import 'package:mobile_controller/pages/components/base_page.dart';
import 'package:mobile_controller/pages/components/fab_menu.dart';
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
  
  // Local state to store discovered devices
  final List<ConnectionConfig> _nearbyDevices = [];

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connectToDevice(ConnectionConfig config) async {
    final success = await ref.read(pairingProvider.notifier).pair(config, null);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pairing failed: Authentication error'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  Future<void> _handleManualConnect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    if (ip.isEmpty) return;
    Navigator.of(context).pop();
    await _connectToDevice(ConnectionConfig.fromMap({'ip': ip, 'port': port, 'type': 'tcp'}));
  }

  void _showManualConnectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          title: const Text('Manual Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _ipController, decoration: const InputDecoration(labelText: 'Server IP', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _portController, decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: _handleManualConnect, child: const Text('Connect')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(nearbyDevicesProvider, (previous, next) {
      debugPrint("Got device");
      final device = next.value;
      if (device != null) {
        final config = device;
        if (config is TcpConfig) {
          if (!_nearbyDevices.any((item) => (item as TcpConfig).ip == config.ip)) {
            setState(() {
              _nearbyDevices.add(config);
            });
          }
        }
      }
    });

    return BasePage(
      title: 'Setup',
      showBackButton: false,
      floatingActionButton: FABbutton(
        labelOpen: 'Add Device',
        labelClose: 'Close',
        options: [
          FABOption(
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => AppRouter.pushRoute(context, AppRoutes.pairingScreen),
            color: theme.colorScheme.primary,
          ),
          FABOption(
            icon: Icons.tune_rounded,
            onPressed: _showManualConnectDialog,
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
      children: [
        buildSectionHeader(context, 'Nearby Devices'),
        const SizedBox(height: AppTheme.spacing),
        
        if (_nearbyDevices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text('Scanning local network...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _nearbyDevices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final config = _nearbyDevices[index];
              final tcpConfig = config as TcpConfig;
              final subtext = 'IP : ${tcpConfig.ip} : Port : ${tcpConfig.port}';
              final deviceName = tcpConfig.deviceName ?? "Unknown Device";

              return Card(
                clipBehavior: Clip.antiAlias,
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer, 
                    child: Icon(Icons.laptop_windows_rounded, 
                      color: theme.colorScheme.onPrimaryContainer, 
                      size: 20)
                    ),
                  title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(subtext),
                  onTap: () => _connectToDevice(config),
                ),
              );
            },
          ),
      ],
    );
  }
}