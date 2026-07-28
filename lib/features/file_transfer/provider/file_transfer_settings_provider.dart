// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/storage/domain/models/file_structure.dart';
import 'package:syncos_android/core/storage/provider/storage_service_provider.dart';

final fileTransferSettingsProvider =
    NotifierProvider<FileTransferSettingsNotifier, FileTransferSettings>(() {
  return FileTransferSettingsNotifier();
});

class FileTransferSettingsNotifier extends Notifier<FileTransferSettings> {
  @override
  FileTransferSettings build() {
    _loadSettings();
    return const FileTransferSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    final savedSettings = await storage.getFileTransferSettings();
    if (savedSettings != null) {
      state = savedSettings;
    }
  }

  Future<void> updateMaxConcurrentTransfers(int maxConcurrentTransfers) async {
    state = state.copyWith(maxConcurrentTransfers: maxConcurrentTransfers);
    final storage = ref.read(storageServiceProvider);
    await storage.setFileSettings(state);
  }

  Future<void> updateNotifyOnCompletion(bool notifyOnCompletion) async {
    state = state.copyWith(notifyOnCompletion: notifyOnCompletion);
    final storage = ref.read(storageServiceProvider);
    await storage.setFileSettings(state);
  }

  Future<void> updateMaxHistoryEntries(int maxHistoryEntries) async {
    state = state.copyWith(maxHistoryEntries: maxHistoryEntries);
    final storage = ref.read(storageServiceProvider);
    await storage.setFileSettings(state);
  }

  Future<void> updateDefaultSaveDirectory(String? path) async {
    state = state.copyWith(
      defaultSaveDirectory: path,
      clearSaveDirectory: path == null,
    );
    final storage = ref.read(storageServiceProvider);
    await storage.setFileSettings(state);
  }

  Future<void> resetToDefault() async {
    state = const FileTransferSettings();
    final storage = ref.read(storageServiceProvider);
    await storage.setFileSettings(state);
  }
}
