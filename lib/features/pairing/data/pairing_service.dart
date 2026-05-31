import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
import 'package:mobile_controller/core/storage/data/storage_service.dart';
import '../../../core/network/domain/i_connection_manager.dart';

class PairingService {
  final IConnectionManager _connectionManager;
  final StorageService _storage;

  PairingService(
    this._connectionManager,
    this._storage,
  );

  Future<bool> pairWithServer(Map<String, dynamic> data) async {
    debugPrint('[PairingService] pairWithServer called with data: $data');
    final config = ConnectionConfig.fromMap(data);


    final statusFuture = _connectionManager.connectionStatusStream
        .firstWhere((s) => s == ConnectionStatus.connected || s == ConnectionStatus.disconnected)
        .timeout(const Duration(seconds: 10));

    final token = data['token'] as String?;


    Future<void> clearFailedPairingState() async {
      debugPrint('[PairingService] clearing stored pairing state after failure');
      await _storage.clearPairingToken();
      await _storage.clearConnectionConfig();
    }


    if (token == null) {
      try {
        await _connectionManager.pair(config);
        debugPrint('[PairingService] pair() requested, waiting for connection status');

        final status = await statusFuture;
        debugPrint('[PairingService] connection status received: $status');

        if (status == ConnectionStatus.connected) {
          debugPrint('[PairingService] manual pairing succeeded, saving config');
          await _storage.setConnectionConfig(config);
          return true;
        }

        debugPrint('[PairingService] manual pairing failed: status=$status');
        await clearFailedPairingState();
        return false;
      } catch (e) {
        debugPrint('[PairingService] Manual pairing failed: $e');
        await clearFailedPairingState();
      }
    } else {
      debugPrint('[PairingService] token present, starting automatic pairing with token');
      try {
        debugPrint('[PairingService] saving temporary pairing token');
        await _storage.setPairingToken(token);

        await _connectionManager.connect(config);

        final status = await statusFuture;
        debugPrint('[PairingService] connection status received: $status');

        if (status == ConnectionStatus.connected) {
          debugPrint('[PairingService] automatic pairing succeeded, saving config');
          await _storage.setConnectionConfig(config);
          return true;
        }

        debugPrint('[PairingService] automatic pairing failed: status=$status');
        await clearFailedPairingState();
        return false;
      } catch (e) {
        debugPrint('[PairingService] Automatic pairing failed: $e');
        await clearFailedPairingState();
      }
    }

    debugPrint('[PairingService] pairing attempt returned false');
    return false;
  }
}