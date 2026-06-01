import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:mobile_controller/core/storage/data/storage_service.dart';

import '../domain/i_connection_manager.dart';
import '../domain/connection_config.dart';
import 'package:flutter/foundation.dart';

class SocketConnectionManager implements IConnectionManager{
  final StorageService _storage;

  SocketConnectionManager(this._storage);

  Socket? _socket;
  final _messageController = StreamController<String>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final BytesBuilder _buffer = BytesBuilder();
  
  ConnectionStatus _status = ConnectionStatus.disconnected;

  ConnectionConfig? _currentConfig;

  Completer<void>? _authCompleter;
  
  // state management
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  bool _isReconnecting = false;
  bool _shouldReconnect = true;
  int _retryCount = 0;

  // ---------------------------------    Getters    -------------------------------------------- 
  
  @override
  ConnectionStatus get status => _status;
  @override
  ConnectionConfig? get activeConfig => _currentConfig;

  @override
  Stream<String> get rawMessageStream => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream =>
      Stream<ConnectionStatus>.multi((controller) {
    // Emit current status immediately for new subscribers
    controller.add(_status);
    final sub = _statusController.stream.listen((s) => controller.add(s));
    controller.onCancel = () => sub.cancel();
  });

  // -----------------------------    Public interface      -------------------------------------

  @override
  Future<void> connect(
    ConnectionConfig config,
  ) async {
    if (config is TcpConfig) {
      if (_status == ConnectionStatus.connecting || _status == ConnectionStatus.connected) return;
      
      _currentConfig = config;

      _status = ConnectionStatus.connecting;
      _statusController.add(_status);

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
    if (config is TcpConfig) {
      _status = ConnectionStatus.pairing;
      _statusController.add(_status);
      
      debugPrint('[Socket] Sending Pair Request');


      await _attemptConnection(config.ip, config.port);
    } else {
      throw UnsupportedError("This manager only supports TCP Connections");
    }
  }


  @override
  void send(String op, String action, Map<String, dynamic> args) {
    if (_socket == null) return;
    final payload = jsonEncode({"op": op, "action": action, "args": args});
    _sendRaw(payload);
  }

  @override
  void disconnect() {
    _shouldReconnect = false;
    _isReconnecting = false;
    _status = ConnectionStatus.disconnected;
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.completeError('Disconnected');
    }
    _cleanup();
    _statusController.add(ConnectionStatus.disconnected);
  }

  /// ------------------      core implementation      ------------------------------
  
  Future<void> _attemptConnection(String ip, int port) async {
    try {
      _authCompleter = Completer<void>();

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
      _triggerReconnect();
    }
  }

  void _processBuffer() {
    while (_buffer.length >= 4) {
      final bytes = _buffer.toBytes();
      final length = ByteData.view(bytes.buffer).getUint32(0, Endian.big);

      if (bytes.length < 4 + length) break; // Wait for more data

      final payload = bytes.sublist(4, 4 + length);
      _buffer.clear();
      if (bytes.length > 4 + length) _buffer.add(bytes.sublist(4 + length));

      try {
        final message = utf8.decode(payload);
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
        _finalizeConnection(token: args['token']);

        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.complete();
        }

      } else if (action == 'rejected') {
        _status = (op == 'auth') ? ConnectionStatus.unauthorized : ConnectionStatus.disconnected;
        _statusController.add(_status);
        _cleanup();

        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.completeError("Rejected");
        }
      }
      return;
    }
    
    if (_status == ConnectionStatus.connected) {
      _messageController.add(jsonEncode(data));
      return;
    }
  }

  void _finalizeConnection({String? token}) {
    _retryCount = 0;
    _isReconnecting = false;

    _status = ConnectionStatus.connected;
    _statusController.add(_status);
    _startHeartbeat();

    if (token != null) _storage.setPairingToken(token);
  }

  void _triggerReconnect() {
    if (!_shouldReconnect) return;

    debugPrint("This is runnin even when unpaired");
    _cleanup();
    _isReconnecting = true;
    _status = ConnectionStatus.reconnecting;
    _statusController.add(_status);

    final delay = min(pow(2, _retryCount).toInt(), 30);

    final config = _currentConfig;

    if(config is TcpConfig) {
      Future.delayed(Duration(seconds: delay), () {
        if (_shouldReconnect && _isReconnecting) {
          _retryCount++;
          _attemptConnection(config.ip, config.port);
        }
      });
    }

  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendRaw('PING');
      _pongTimeoutTimer = Timer(const Duration(seconds: 10), _handleError);
    });
  }

  void _sendRaw(String msg) {
    try{
      final data = utf8.encode(msg);
      final header = ByteData(4)..setUint32(0, data.length, Endian.big);
      _socket?.add(header.buffer.asUint8List());
      _socket?.add(data);
    } catch(_) {}
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _socket?.destroy();
    _socket = null;
  }


  void _handleError() => _triggerReconnect();

  void _sendAuth(String token) {
    if (_socket == null) return;
    final payload = jsonEncode({"op": 'auth', "action": "", "args": {"token": token}});
    _sendRaw(payload);
  }

  void _pair() {
    if (_socket == null) return;
    final payload = jsonEncode({"op": 'pair', "action": "", "args": {}});
    _sendRaw(payload);
  }
}