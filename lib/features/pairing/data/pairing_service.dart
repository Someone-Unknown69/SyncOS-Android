import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
import '../../../services/storage_service.dart';
import '../../../core/network/domain/i_connection_manager.dart';

class PairingService {
  final IConnectionManager _connectionManager;

  PairingService(this._connectionManager);

  Future<bool> pairWithServer(Map<String, dynamic> data) async {
    final ip = data['ip'];
    final port = data['port'];
    final token = data['token'];

    final TcpConfig config = TcpConfig(host: ip, port: port);

    final statusFuture = _connectionManager.connectionStatusStream
        .firstWhere((s) => s == ConnectionStatus.connected || s == ConnectionStatus.disconnected)
        .timeout(const Duration(seconds: 10));

    // Connect using the existing connection manager
    await _connectionManager.connect(config, token: token);

    try {
     final status = await statusFuture;

      if(status == ConnectionStatus.connected) {
        await StorageService.setServerIp(ip);
        await StorageService.setServerPort(port);
        await StorageService.setPairingToken(token);
        return true;
      }
    } catch (e) {
      debugPrint('[PairingService] Pairing timed out or failed: $e');
    }
    return false;
  }
}