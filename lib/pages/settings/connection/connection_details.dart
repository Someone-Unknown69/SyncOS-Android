// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/domain/connection_config.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/core/storage/provider/storage_service_provider.dart';
import 'package:syncos_android/pages/components/base_page.dart';
import 'package:syncos_android/pages/components/setting_components.dart';
import 'package:syncos_android/theme/app_theme.dart';

final _connectionStatusProvider = Provider<ConnectionStatus>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  final statusAsync = ref.watch(StreamProvider((ref) => connectionManager.connectionStatusStream));
  return statusAsync.value ?? connectionManager.status;
});

final _pairingTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getPairingToken();
});

class ConnectionDetails extends ConsumerStatefulWidget {
  const ConnectionDetails({super.key});

  @override
  ConsumerState<ConnectionDetails> createState() =>
      _ConnectionDetailsState();
}

class _ConnectionDetailsState
    extends ConsumerState<ConnectionDetails> {
  bool _showToken = false;

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pairing token copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(_connectionStatusProvider);
    final tokenAsync = ref.watch(_pairingTokenProvider);
    final connectionManager = ref.watch(connectionManagerProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final config = connectionManager.serverConfig;
    final isConnected = status == ConnectionStatus.connected;
    final statusLabel = isConnected ? 'Connected' : 'Disconnected';
    final statusMessage = isConnected
        ? 'Your device is currently connected.'
        : 'No active connection at the moment.';

    return BasePage(
      title: 'Connection Details',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Connection Status'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.padding),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.power_off_rounded,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: AppTheme.spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                          ),

                          Text(
                            statusMessage,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (config is TcpConfig) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Server Details',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 20,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing),

                      Text(
                        'IP address',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing / 8),
                      Text(
                        config.ip,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing / 2),

                      Text(
                        'Port',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing / 8),

                      Text(
                        config.port.toString(),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing / 2),

                      tokenAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: AppTheme.spacing),
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, _) => Text(
                          'Unable to load token.',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        data: (token) {
                          final tokenText = token != null && token.isNotEmpty
                              ? (_showToken ? token : '••••••••••••••••••')
                              : 'No token stored.';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pairing token',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: token == null || token.isEmpty
                                        ? null
                                        : () {
                                            setState(() {
                                              _showToken = !_showToken;
                                            });
                                          },
                                    child: Text(
                                      _showToken ? 'Hide' : 'Show',
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: token == null || token.isEmpty
                                    ? null
                                    : () => _copyToken(token),
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tokenText,
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (token != null && token.isNotEmpty)
                                        Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing / 2),
                              if (token != null && token.isNotEmpty)
                                Text(
                                  '*Tap the token to copy it.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing),
                child: Text(
                  isConnected
                      ? 'Connected, but connection details are unavailable.'
                      : 'No saved connection details are available.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        )
      ],
    );
  }
}
