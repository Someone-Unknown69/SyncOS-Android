import 'package:flutter/material.dart';
import '../../../core/globals.dart';
import '../../../theme/app_theme.dart';

class TransferSnackbar {
  static void show({
    required String label,
    required String fileName,
    required int fileSize,
    required ValueNotifier<double> progressNotifier,
    required Future<void> task,
    VoidCallback? onCancel,
  }) {
    final state = snackbarKey.currentState;
    final context = snackbarKey.currentContext;
    if (state == null || context == null) return;

    final theme = Theme.of(context);
    final String sizeStr = "${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB";

    state.hideCurrentSnackBar();
    state.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
        content: ValueListenableBuilder<double>(
          valueListenable: progressNotifier,
          builder: (context, progress, child) {
            final bool isInitializing = progress <= 0;
            final bool isComplete = progress >= 1.0;
            final Color accentColor = isComplete ? AppTheme.successColor : theme.colorScheme.primary;

            return Padding(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isComplete ? Icons.check_circle : (isInitializing ? Icons.hourglass_top : Icons.sync),
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isComplete ? "Success" : (isInitializing ? "Initializing" : label),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!isInitializing && !isComplete)
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // File Information
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isInitializing ? "Preparing file for transfer..." : "Size: $sizeStr",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // The Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    child: LinearProgressIndicator(
                      value: isInitializing ? null : (isComplete ? 1.0 : progress),
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (!isComplete && onCancel != null) onCancel();
                        snackbarKey.currentState?.hideCurrentSnackBar();
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: isComplete ? AppTheme.successColor : theme.colorScheme.error,
                      ),
                      child: Text(isComplete ? "DISMISS" : "CANCEL"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    task.then((_) {
      progressNotifier.value = 1.0;
      Future.delayed(const Duration(seconds: 3), () {
        snackbarKey.currentState?.hideCurrentSnackBar();
      });
    }).catchError((e) {
      _showError("Transfer Failed: $e");
    });
  }

  static void _showError(String msg) {
    snackbarKey.currentState?.hideCurrentSnackBar();
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
