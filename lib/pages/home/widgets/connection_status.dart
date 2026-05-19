import 'package:flutter/material.dart';
import '../../../core/globals.dart';
import '../../../theme/app_theme.dart';

class StatusWaiting extends StatelessWidget {
  final String message;

  const StatusWaiting({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spacing),
            Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  strokeWidth: 3,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Please ensure your computer is awake and SyncOS server is running.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatusDisconnected extends StatelessWidget {
  final VoidCallback onReconnect;

  const StatusDisconnected({super.key, required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Disconnected",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppTheme.spacing),
            
            // Button for connection
            FilledButton.icon(
              onPressed: onReconnect,
              icon: const Icon(Icons.refresh),
              label: const Text("Reconnect"),
              style: ElevatedButton.styleFrom(
                elevation: 2, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusConnected extends StatelessWidget {
  const StatusConnected({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder(
              valueListenable: processor.deviceName,
              builder: (context, name, child) {
                return Text(name, style: const TextStyle(fontWeight: FontWeight.bold));
              },
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Display battery info and charging status
                    ValueListenableBuilder(
                      valueListenable: processor.batteryLevel, 
                      builder: (context, level, child) {
                        return ValueListenableBuilder(
                          valueListenable: processor.isCharging, 
                          builder: (context, charging, child) {
                            return Icon(
                              charging ? Icons.battery_charging_full : Icons.battery_std,
                              color: level < 20 ? AppTheme.errorColor : AppTheme.successColor,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: processor.batteryLevel, 
                      builder: (context, level, child) => Text("$level% remaining")
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing),

            Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // disconnect button
                FilledButton.icon(
                  onPressed: () => client.handleDisconnect(),
                  icon: const Icon(Icons.power_off),
                  label: const Text("Disconnect"),
                  style: FilledButton.styleFrom(
                    elevation: 0, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: colorScheme.surfaceBright,
                  ),
                ),

                const SizedBox(width: AppTheme.spacing),

                // Ping button
                FilledButton.icon(
                  onPressed: () => client.send("PING", "", {}),
                  icon: const Icon(Icons.network_ping_rounded),
                  label: const Text("Ping"),
                  style: FilledButton.styleFrom(
                    elevation: 0, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    backgroundColor: colorScheme.primary,
                  ),
                ),

              ],
            )
          ],
        ),
      ),
    );
  }
}
