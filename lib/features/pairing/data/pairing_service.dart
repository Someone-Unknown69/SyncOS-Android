// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:syncos_android/core/network/domain/connection_config.dart';
import 'package:syncos_android/core/storage/data/storage_service.dart';
import '../../../core/network/domain/i_connection_manager.dart';

class PairingService {
  final IConnectionManager _connectionManager;
  final StorageService _storage;

  PairingService(
    this._connectionManager,
    this._storage,
  );

  Future<bool> pairWithServer(ConnectionConfig config, String? token) async {
    debugPrint('[PairingService] pairWithServer called with data: ${config.toJson()}');

    final statusFuture = _connectionManager.connectionStatusStream
    .where((s) => s == ConnectionStatus.connected || s == ConnectionStatus.unauthorized) // Filter out everything else
    .first // Take the first successful connection or unauthorized connection
    .timeout(const Duration(seconds: 10));


    if (token == null) {
      try {
        await _connectionManager.pair(config);
        debugPrint('[PairingService] pair() requested, waiting for connection status');

        final status = await statusFuture;
        debugPrint('[PairingService] connection status received: $status');

        if (status == ConnectionStatus.connected) {

          debugPrint('[PairingService] manual pairing succeeded, saving ${config.toJson()}');
          await _storage.setConnectionConfig(config);
          return true;
        }

        debugPrint('[PairingService] manual pairing failed: status=$status');
        await _clearFailedPairingState();
        return false;
      } catch (e) {
        debugPrint('[PairingService] Manual pairing failed: $e');
        await _clearFailedPairingState();
        return false;
      }
    } else {
      debugPrint('[PairingService] token present as $token, starting automatic pairing with token');
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
        await _clearFailedPairingState();
        return false;
      } catch (e) {
        debugPrint('[PairingService] Automatic pairing failed: $e');
        await _clearFailedPairingState();
      }
    }

    debugPrint('[PairingService] pairing attempt returned false');
    return false;
  }

  Future<bool> unpairWithServer() async {
    try {
      await _connectionManager.unpair();
      debugPrint('[PairingService] Unpaired device successfully');
      return true;
    } catch (e) {
      debugPrint('[PairingService] Error in unpairing : $e');
      return false;
    }
  }

  Future<void> _clearFailedPairingState() async {
    debugPrint(StackTrace.current.toString());
    debugPrint('[PairingService] clearing stored pairing state after failure');
    await _storage.clearPairingToken();
    await _storage.clearConnectionConfig();
  }
}