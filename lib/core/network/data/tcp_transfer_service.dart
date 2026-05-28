import 'dart:io';
import 'dart:async';
import '../domain/i_file_transfer_manager.dart';

// In case of changing the file transfer implementation to server based or bluetooth based
// the connection logic shall be added in this file
// This is the file transfer infrastrucre

class TcpTransferTransport implements IFileTransferManager {
  @override
  Future<(StreamSink<List<int>>, Map<String, dynamic>)> send() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    
    // We include the host here so the receiver knows exactly where to look
    final metadata = {
      'port': server.port,
      'host': server.address,
    };
    
    final socket = await server.first.timeout(const Duration(seconds: 30));
    await server.close();
    
    return (socket, metadata);
  }

  @override
  Future<Stream<List<int>>> receive(Map<String, dynamic> connectionInfo) async {
    return await Socket.connect(connectionInfo['host'], connectionInfo['port']);
  } 
}