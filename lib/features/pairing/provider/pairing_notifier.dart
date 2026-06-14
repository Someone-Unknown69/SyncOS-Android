// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

// lib/features/pairing/provider/pairing_notifier.dart
import 'package:syncos_android/core/network/domain/connection_config.dart';
import 'package:syncos_android/core/storage/provider/storage_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/pairing_service.dart';
import '../../../core/network/provider/connection_provider.dart';

part 'pairing_notifier.g.dart';

@riverpod
class PairingNotifier extends _$PairingNotifier {
  @override
  bool build() => false; // false = idle, true = pairing in progress

  Future<bool> pair(ConnectionConfig config, String? token) async {
    state = true; // Start loading
    try {
      final manager = ref.read(connectionManagerProvider);
      final storage = ref.read(storageServiceProvider);
      final service = PairingService(manager, storage);
      final result = await service.pairWithServer(config, token);
      return result;
    } catch (e) {
      return false;
    } finally {
      if (ref.mounted) {
        state = false; // Stop loading
      }
    }
  }

  Future<bool> unpairWithServer() async {
    state = true;
    try {
      final manager = ref.read(connectionManagerProvider);
      final storage = ref.read(storageServiceProvider);
      final service = PairingService(manager, storage);
      final result = await service.unpairWithServer();
      return result;
    } catch (e) {
      return false;
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}