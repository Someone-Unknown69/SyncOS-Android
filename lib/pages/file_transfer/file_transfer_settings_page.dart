// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/file_transfer/provider/file_transfer_notifier.dart';
import 'package:syncos_android/features/file_transfer/provider/file_transfer_settings_provider.dart';
import 'package:syncos_android/pages/components/base_page.dart';
import 'package:syncos_android/pages/components/setting_components.dart';
import 'package:syncos_android/pages/components/popup_dialog.dart';
import 'package:syncos_android/theme/app_theme.dart';

class FileTransferSettingsPage extends ConsumerWidget {
  const FileTransferSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(fileTransferSettingsProvider);
    final notifier = ref.read(fileTransferSettingsProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BasePage(
      title: 'File Transfer Settings',
      showBackButton: true,
      children: [
        const SectionHeader(title: 'Notifications'),
        SettingsTile(
          icon: Icons.notifications_active_rounded,
          title: 'Enable File Transfer Notification',
          subtitle: 'Show notification when file transfer completes',
          trailing: Switch(
            value: settings.notifyOnCompletion,
            onChanged: (value) {
              notifier.updateNotifyOnCompletion(value);
            },
          ),
        ),

        const SectionHeader(title: 'History & Storage'),
        SettingsDropdownSection<int>(
          icon: Icons.history_rounded,
          title: 'Max History Log Entries',
          subtitle: 'Limit total stored transfer history records',
          value: settings.maxHistoryEntries,
          items: const [
            DropdownMenuItem(value: 25, child: Text('25 entries')),
            DropdownMenuItem(value: 50, child: Text('50 entries')),
            DropdownMenuItem(value: 100, child: Text('100 entries (Default)')),
            DropdownMenuItem(value: 250, child: Text('250 entries')),
          ],
          onChanged: (value) {
            if (value != null) {
              notifier.updateMaxHistoryEntries(value);
            }
          },
        ),

        SettingsTile(
          icon: Icons.delete_sweep_rounded,
          title: 'Clear History',
          subtitle: 'Delete all saved transfer records',
          onTap: () async {
            await showAppPopupDialog(
              context,
              title: 'Clear Transfer History',
              subtitle: 'Are you sure you want to remove all file transfer records?',
              primaryButtonLabel: 'Clear All',
              secondaryButtonLabel: 'Cancel',
              onPrimaryPressed: () {
                ref.read(fileTransferState.notifier).clearHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transfer history cleared')),
                );
              },
            );
          },
        ),

        const SizedBox(height: AppTheme.spacing),
        Center(
          child: TextButton.icon(
            onPressed: () {
              notifier.resetToDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to default')),
              );
            },
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset to Defaults'),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
