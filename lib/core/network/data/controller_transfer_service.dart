// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/network/domain/connection_config.dart';
import 'package:syncos_android/core/network/domain/i_controller_transfer_service.dart';

class ControllerTransferService implements IControllerTransferService {
  final port = 4242;

  RawDatagramSocket? _socket;
  InternetAddress? _serverAddress;

  @override
  Future<void> connect(ConnectionConfig config) async {
    if (_socket != null) {
      logDebug('Controller Transfer Service', 'Client already running');
      return;
    }

    if (config is TcpConfig) {
      try {
        final serverIp = config.ip;
        _serverAddress = InternetAddress(serverIp);

        // Bind to any available local address and port chosen by the OS
        _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

        _socket!.readEventsEnabled = false;
        _socket!.writeEventsEnabled = false;

        logDebug('Controller Transfer Service', 'UDP Socket bound. Target: $serverIp:$port');
      } catch (e) {
        logDebug('Controller Transfer Service', 'Failed to bind client socket: $e');
        rethrow;
      }
    } else {
      logDebug(
        'Controller Transfer Service',
        'Invalid Config type , expected a TCP Config',
      );
    }
  }

  @override
  void sendUpdate(Uint8List payload) {
    if (_socket == null || payload.length != 6) return;
    _socket!.send(payload, _serverAddress!, port);
  }

  @override
  Future<void> disconnect() async {
    if (_socket == null) return;

    _socket!.close();
    _socket = null;
    _serverAddress = null;
    logDebug('Controller Transfer Service', 'Socket shut down cleanly');
  }
}
