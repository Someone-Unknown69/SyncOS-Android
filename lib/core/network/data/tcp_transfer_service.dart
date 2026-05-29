import 'dart:io';
import 'dart:async';
import '../domain/i_file_transfer_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// In case of changing the file transfer implementation to server based or bluetooth based
// the connection logic shall be added in this file
// This is the file transfer infrastrucre

class TcpTransferTransport implements IFileTransferManager {
  @override
  Future<(Future<Socket>, Map<String, dynamic>)> send() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    
    final localIp = await _getLocalIpAddress();

    // We include the host here so the receiver knows exactly where to look
    final metadata = {
      'port': server.port,
      'host': localIp ?? '127.0.0.1',
    };

    debugPrint('[FTP] Server bound on port ${server.port}. Waiting for connection...');

    final connectionFuture = server.first.then((socket) {
      server.close(); // Clean up the server listener once connected
      return socket;
    });
    
    return (connectionFuture, metadata);
  }

  @override
  Future<Stream<List<int>>> receive(Map<String, dynamic> connectionInfo) async {
    return await Socket.connect(connectionInfo['host'], connectionInfo['port']);
  } 

  Future<String?> _getLocalIpAddress() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      final info = NetworkInfo();
      return await info.getWifiIP(); 
    }
    return null;
  }
}