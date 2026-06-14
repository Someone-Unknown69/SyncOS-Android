// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import '../../../theme/app_theme.dart';

class StatusDisconnected extends ConsumerWidget {
  const StatusDisconnected({super.key});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  final connectionManager = ref.watch(connectionManagerProvider);
  
  final status = ref.watch(connectionStatusProvider).maybeWhen(
      data: (s) => s,
      orElse: () => ConnectionStatus.disconnected,
  );

  final bool isAttempting = status != ConnectionStatus.disconnected;

  return Card(
    elevation: 0,
    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius * 1.5),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.padding * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.laptop_rounded, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppTheme.spacing),
          Text(
            "Laptop Disconnected",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacing / 2),
          Text(
            "Your connection to the machine has been lost.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacing * 2),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: isAttempting ? null : () => connectionManager.start(),
                icon: isAttempting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync_rounded),
                label: Text(isAttempting ? "Attempting..." : "Attempt Reconnect"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              
              if (isAttempting) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    connectionManager.stopDiscovery();
                  },
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ],
            ],
          ),
                    
          const SizedBox(height: AppTheme.spacing * 2),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppTheme.spacing),
          
          // Troubleshooting Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Troubleshooting Tips:",
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppTheme.spacing),
          _buildTip(theme, Icons.wifi, "Ensure that both devices are on the same Wi-Fi network."),
          _buildTip(theme, Icons.check_circle_outline, "Verify the remote server is running."),
          _buildTip(theme, Icons.airplanemode_off, "Check that Airplane mode is disabled."),
        ],
      ),
    ),
  );
}

  Widget _buildTip(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}