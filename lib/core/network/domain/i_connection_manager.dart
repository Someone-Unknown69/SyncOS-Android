import '../domain/connection_config.dart';

// Domain interface for connection manager 
// Any connection services must match the following blueprint
enum ConnectionStatus {
  connected,       // Fully authenticated, connection is active and authorized
  disconnected,    // connection is inactive
  connecting,      // Establishing connection
  reconnecting,    
  unauthorized,    // used for Auth/ token issues
  pairing,         // for initial connection
}

abstract class IConnectionManager {
  // streams
  Stream<String> get rawMessageStream;
  Stream<ConnectionStatus> get connectionStatusStream;
  Stream<(ConnectionConfig, String)> get nearbyDevicesStream;

  // status
  ConnectionConfig? get activeConfig;
  ConnectionStatus get status;

  void start();

  // Discovers nearby devices
  void discoverDevices();
  void stopDiscovery();
  
  // connection and authorization
  Future<void> autoConnectionStart();
  Future<void> connect(ConnectionConfig config);
  void disconnect();

  Future<void> pair(ConnectionConfig config);
  Future<void> unpair();

  // The implementation handles the serialization.
  void send(String op, String action, Map<String, dynamic> args);
}