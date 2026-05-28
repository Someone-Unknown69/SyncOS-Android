import '../domain/connection_config.dart';

// Domain interface for connection manager 
// Any connection services must match the following blueprint
enum ConnectionStatus {connected, disconnected, connecting, reconnecting}

abstract class IConnectionManager {
  Stream<String> get rawMessageStream;
  Stream<ConnectionStatus> get connectionStatusStream;
  ConnectionConfig? get activeConfig;
  void send(String op, String action, Map<String, dynamic> args);
  Future<void> connect(ConnectionConfig config, {String? token});
  void disconnect();
}