import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:mobile_controller/core/storage/data/storage_service.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/i_connection_manager.dart';
import '../domain/connection_config.dart';
import 'package:flutter/foundation.dart';

class SocketConnectionManager implements IConnectionManager{
  final StorageService _storage;

  SocketConnectionManager(this._storage);

  Socket? _socket;
  final _messageController = StreamController<String>.broadcast();
  final _statusController = BehaviorSubject<ConnectionStatus>.seeded(
    ConnectionStatus.disconnected,
  );
  final _nearbyDevicesController = StreamController<ConnectionConfig>.broadcast();
  final BytesBuilder _buffer = BytesBuilder();
  
  ConnectionConfig? _serverConfig;

  Completer<void>? _authCompleter;
  
  // discovery Socket
  RawDatagramSocket? _udpSocket;
  
  // state management
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  final int _discoveryPort = 6767;

  RawDatagramSocket? _discoverySocket;
  RawDatagramSocket? _autoConnectSocket;
  
  final Set<ConnectionConfig> _discoveredConfigsCache = {};

  // ---------------------------------    Getters    -------------------------------------------- 
  
  @override
  ConnectionStatus get status => _statusController.value;
  @override
  ConnectionConfig? get serverConfig => _serverConfig;

  @override
  Stream<String> get rawMessageStream => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;

  @override
  Stream<ConnectionConfig> get nearbyDevicesStream => _nearbyDevicesController.stream;

  // -----------------------------    Public interface      -------------------------------------

  @override
  void start() async {
    final isPaired = await _storage.isPaired;

    if(isPaired) {
      _statusController.add(ConnectionStatus.listening);
      autoConnectionStart();
    } else {
      _statusController.add(ConnectionStatus.pairing);
      discoverDevices();
    }
  }

  @override
  void discoverDevices() async {
    try {
      stopDiscovery(); 
      _discoveredConfigsCache.clear();

      _discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _discoveryPort);
      debugPrint('[Pairing] Discovering nearby devices...');

      final currentSocket = _discoverySocket;
      if (currentSocket == null) return;

      await for (RawSocketEvent event in currentSocket) {
        if (_discoverySocket == null) break;

        if (event == RawSocketEvent.read) {
          Datagram? dg = currentSocket.receive();
          if (dg == null) continue;

          try {
            final Map<String, dynamic> payload = jsonDecode(utf8.decode(dg.data));

            if (payload['service'] == 'SyncOS-server' && payload['status'] == 'pairing_mode') {
              final discoveredConfig = ConnectionConfig.fromMap(payload['config']);

              debugPrint("[Pairing] New Server Discovered: ${payload['config']}");
              _nearbyDevicesController.add(discoveredConfig);

              if (!_discoveredConfigsCache.contains(discoveredConfig)) {
                _discoveredConfigsCache.add(discoveredConfig);

              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[Pairing] Binding error: $e');
    }
  }

  @override
  void stopDiscovery() {
    if(status != ConnectionStatus.connected) {
      // Any case where we are already not connected, add disconnected
      _statusController.add(ConnectionStatus.disconnected);
    }
    debugPrint('[Socket] Stopping all discovery/auto-connect sockets');
    
    _discoverySocket?.close();
    _discoverySocket = null;
    
    _autoConnectSocket?.close();
    _autoConnectSocket = null;
    
    _udpSocket?.close();
    _udpSocket = null;
  }

  @override
  Future<void> autoConnectionStart() async {
    // return when already listening
    if(status != ConnectionStatus.listening) return;

    try {
      _autoConnectSocket?.close();
      _autoConnectSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 
        _discoveryPort,
        reuseAddress: true,
      );
      debugPrint('[Socket] Auto Connection Turned ON');

      final currentSocket = _autoConnectSocket;
      if (currentSocket == null) return;

      await for (RawSocketEvent event in currentSocket) {
        if (_autoConnectSocket == null) break;

        if (event == RawSocketEvent.read) {
          Datagram? dg = currentSocket.receive();
          if (dg == null) continue;


          try {
            final Map<String, dynamic> payload = jsonDecode(utf8.decode(dg.data));


            if (payload['service'] == 'SyncOS-server') {
              
              final String serverTimestamp = payload['timestamp'] ?? '';
              final String serverSignature = payload['signature'] ?? '';

              final localToken = await _storage.getPairingToken();
              if (localToken == null || localToken.isEmpty) {
                debugPrint('[Auto Connect] No pairing token stored locally, Aborting.');
                continue;
              }

              final config = ConnectionConfig.fromMap(payload['config']);

              // Verify server authenticity
              final bool isVerified = _verifyServerHMAC(serverTimestamp, serverSignature, localToken);

              if (!isVerified) {
                debugPrint('[Security Warning] Received unauthenticated verification');
                continue;
              }

              debugPrint('[Auto Connect] Valid authentication identity.');
              
              // close and connect natively
              _autoConnectSocket?.close();
              _autoConnectSocket = null;

              await connect(config);
              return;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[Auto Connect] Passive loop fault: $e');
    }
  }

  /// securityyyyyy
  bool _verifyServerHMAC(String timestampStr, String signature, String secretKey) {
    try {
      final int serverTime = int.parse(timestampStr);
      final int localTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Packet must be created within the last 15 seconds
      if ((localTime - serverTime).abs() > 15) {
        debugPrint('[Security] Expired packet verification dropped. Diff: ${(localTime - serverTime).abs()}s');
        return false;
      }

      // Compute local comparison hash
      final keyBytes = utf8.encode(secretKey);
      final messageBytes = utf8.encode(timestampStr);

      final hmac = Hmac(sha256, keyBytes);
      final computedSignature = hmac.convert(messageBytes).toString();

      return computedSignature == signature;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> connect(
    ConnectionConfig config,
  ) async {
    // Stop discovering clients if it is called by pairing screen
    stopDiscovery();

    if (config is TcpConfig) {
      if (status == ConnectionStatus.connecting || status == ConnectionStatus.connected) return;
      
      _serverConfig = config;
      _statusController.add(ConnectionStatus.connecting);

      debugPrint('[Socket] Initializing TCP connection to ${config.ip}');
      await _attemptConnection(config.ip, config.port);
    } else {
      throw UnsupportedError("This manager only supports TCP connections");
    }
  }

  @override
  Future<void> pair(
    ConnectionConfig config,
  ) async {
    stopDiscovery();
    
    if (config is TcpConfig) {
      _statusController.add(ConnectionStatus.pairing);
      
      debugPrint('[Socket] Sending Pair Request');

      await _attemptConnection(config.ip, config.port);
    } else {
      throw UnsupportedError("This manager only supports TCP Connections");
    }
  }

  @override
  Future<void> unpair() async {
    try {
      await _sendRaw(jsonEncode({'op': 'unpair'}), compress: false);
    } catch (e) {
      debugPrint('[Socket] Could not notify server of unpair, forcing local cleanup.');
    }
    await _performFullTeardown(clearStorage: true);
    debugPrint('[Socket] Device unpaired and storage cleared.');

    discoverDevices();
    debugPrint('[Socket] Device Discovery started');
  }

  @override
  void send(String op, String action, Map<String, dynamic> args) async {
    if (_socket == null) return;
    final payload = jsonEncode({"op": op, "action": action, "args": args});
    await _sendRaw(payload);
  }

  @override
  void disconnect() {
    _performFullTeardown(clearStorage: false);
    debugPrint('[Socket] Manual disconnect.');
  }

  /// ------------------      core implementation      ------------------------------
  
  Future<void> _attemptConnection(String ip, int port) async {
    try {
      _authCompleter = Completer<void>();
      _cleanup();

      // TODO : Implement secure socket on both sides
      _socket = await Socket.connect(
        ip, 
        port, 
        timeout: const Duration(seconds: 5),
        // onBadCertificate: (X509Certificate cert) => true, 
      );
    
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      _socket!.listen(
        (data) {
          _buffer.add(data);
          _processBuffer();
        },
        onError: (e) => _handleError(),
        onDone: _handleError,
      );

      // Check if token is available
      final token = await _storage.getPairingToken();

      if(token == null || token.isEmpty) {
        // wait for server to manually accept and store the coming token
        _pair();
      } else {
        // send the token and wait for authentication
        _sendAuth(token);
      }

      await _authCompleter!.future.timeout(const Duration(seconds: 5));
      debugPrint("[Socket] Authentication successful, entering data mode");
    } catch(e) {
      debugPrint('[Socket] Connection failed: $e');
      _statusController.add(ConnectionStatus.listening);
      autoConnectionStart();
    }
  }

  void _processBuffer() {
    while (_buffer.length >= 4) {
      final bytes = _buffer.toBytes();
      final length = ByteData.view(bytes.buffer).getUint32(0, Endian.big);

      if (bytes.length < 4 + length) break;

      final payload = bytes.sublist(4, 4 + length);
      _buffer.clear();
      if (bytes.length > 4 + length) _buffer.add(bytes.sublist(4 + length));

      try {
        final String message;
        if (payload.length >= 2 && payload[0] == 0x1F && payload[1] == 0x8B) {
          message = utf8.decode(gzip.decode(payload));
        } else {
          message = utf8.decode(payload);
        }

        if (message == 'PONG') {
          _pongTimeoutTimer?.cancel();
          continue;
        }

        final data = jsonDecode(message) as Map<String, dynamic>;
        _handleProtocolMessage(data);
      } catch (e) {
        debugPrint('[Socket] Error parsing message: $e');
      }
    }
  }

  void _handleProtocolMessage(Map<String, dynamic> data) {
    final op = data['op'] as String?;
    final action = data['action'] as String?;
    final args = data['args'] as Map<String, dynamic>? ?? {};

    // Handle Handshakes
    if (op == 'auth' || op == 'pair') {
      if (action == 'accepted') {
        _finalizeConnection(
          token: args['token'],
          config: args['config'],
        );

        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.complete();
        }

      } else if (action == 'rejected') {
        final failureState = (op == 'auth') ? ConnectionStatus.unauthorized : ConnectionStatus.disconnected;
        _statusController.add(failureState);
        _cleanup();

        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.completeError("Rejected");
        }
      }
      return;
    }

    if(op == 'unpair') {
      _clearConnectionInfo();
      disconnect();
      debugPrint('[Socket] Remote device unpaired');
    }
    
    if (status == ConnectionStatus.connected) {
      _messageController.add(jsonEncode(data));
      return;
    }
  }

  void _finalizeConnection({String? token, Map<String, dynamic>? config}) {
    debugPrint("[Socket] Finalizing connection with token $token");

    _statusController.add(ConnectionStatus.connected);
    _startHeartbeat();

    if (token != null) _storage.setPairingToken(token);
    if (config != null) _storage.setConnectionConfig(ConnectionConfig.fromMap(config));
  }

  void _handleConnectionLoss() {
    _cleanup();

    // No need to start autoconnnect when already listening
    if(status == ConnectionStatus.listening) return;
    
    if (status == ConnectionStatus.pairing) {
      // If it was pairing we will set to disconnected and will start pairing once again
      _statusController.add(ConnectionStatus.disconnected);
      discoverDevices();
    } else if(status != ConnectionStatus.disconnected) {
      _statusController.add(ConnectionStatus.listening);
      autoConnectionStart();
    }
  }

  Future<void> _performFullTeardown({bool clearStorage = false}) async {
    // Storage clear false will be case for manual disconnect and 
    // Storage clear true will be case of unpairing

    debugPrint('[Socket] Performing full teardown. Storage clear: $clearStorage');
    _statusController.add(ConnectionStatus.disconnected);

    if (clearStorage) {
      await _clearConnectionInfo();
    } 
    
    stopDiscovery();

    _cleanup();
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _socket?.destroy();
    _socket = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendRaw('PING');

      _pongTimeoutTimer = Timer(const Duration(seconds: 10), _handleError);
    });
  }

  Future<void> _sendRaw(String msg, {bool compress = true}) async {
    try {
      final rawBytes = utf8.encode(msg);
      
      final List<int> payload = compress ? gzip.encode(rawBytes) : rawBytes;

      final lengthBytes = ByteData(4)..setUint32(0, payload.length, Endian.big);
      
      final socket = _socket;
      
      socket!.add(lengthBytes.buffer.asUint8List());
      socket.add(payload);
    } catch (e) {
      debugPrint('[Server/Client] Send raw error: $e');
    }
  }

  Future<void> _clearConnectionInfo() async {
    try {
      await _storage.clearConnectionConfig();
      await _storage.clearPairingToken();
      _cleanup();

      debugPrint('[Socket] Paired device Info cleared successfully');
    } catch (e) {
      debugPrint('[Socket] Error while clearing connection info of unpaired device');
    }
  }

  void _handleError() => _handleConnectionLoss();

  void _sendAuth(String token) {
    _sendRaw(jsonEncode({"op": 'auth', "args": {"token": token}}), compress: false);
  }

  void _pair() {
    _sendRaw(jsonEncode({"op": 'pair', "args": {}}), compress: false);
  }
}