import 'package:flutter/material.dart';
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
