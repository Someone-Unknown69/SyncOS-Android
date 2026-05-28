import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import '../domain/i_connection_manager.dart';
import '../domain/connection_config.dart';
import 'package:flutter/foundation.dart';

class SocketConnectionManager implements IConnectionManager{
  Socket? _socket;
  final _messageController = StreamController<String>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final BytesBuilder _buffer = BytesBuilder();
  
  ConnectionConfig? _currentConfig;
  String? _pairingToken;
  
  // state management
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  bool _isReconnecting = false;
  int _retryCount = 0;

  @override
  ConnectionConfig? get activeConfig => _currentConfig;

  @override
  Stream<String> get rawMessageStream => _messageController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;

  ///    ----------------      Public interface      -----------------------

  @override
  Future<void> connect(ConnectionConfig config, {String? token}) async {
    if (config is TcpConfig) {
      _pairingToken = token;
      _currentConfig = config;
      debugPrint('[Socket] Initializing TCP connection to ${config.host}');

      await _attemptConnection(config.host, config.port, token);
    } else {
      throw UnsupportedError("This manager only supports TCP connections");
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
    _isReconnecting = false;
    _cleanup();
    _statusController.add(ConnectionStatus.disconnected);
  }

  /// ------------------      core implementation      ------------------------------
  
  Future<void> _attemptConnection(String host, int port, String? pairingToken) async {
    _statusController.add(ConnectionStatus.connecting);

    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      if(pairingToken == null) _sendAuth();

      _socket!.listen(
        (data) {
          _buffer.add(data);
          _processBuffer();
        },
        onError: (e) => _handleError(),
        onDone: _handleError,
      );

      _statusController.add(ConnectionStatus.connected);
      _startHeartbeat();
      _retryCount = 0;
      _isReconnecting = false;

    } catch(e) {
      debugPrint('[Socket] Connection failed: $e');
      _triggerReconnect();
    }
  }

  void _processBuffer() {
    while(_buffer.length >= 4) {
      final bytes = _buffer.toBytes();
      final length = ByteData.view(bytes.buffer).getUint32(0, Endian.big);      

      if(bytes.length > 4 + length) {
        final payload = bytes.sublist(4, 4 + length);
        final message = utf8.decode(payload);

        if(message == 'PONG') {
          _pongTimeoutTimer?.cancel();
        } else {
          _messageController.add(message);
        } 

        _buffer.clear();
        if (bytes.length > 4 + length) _buffer.add(bytes.sublist(4 + length));
      } else {
        break;
      }
    }
  }

  void _triggerReconnect() {
    _cleanup();
    _isReconnecting = true;
    _statusController.add(ConnectionStatus.reconnecting);

    final delay = min(pow(2, _retryCount).toInt(), 30);

    final config = _currentConfig;

    if(config is TcpConfig) {
      Future.delayed(Duration(seconds: delay), () {
        if (_isReconnecting) {
          _retryCount++;
          _attemptConnection(config.host, config.port, _pairingToken);
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

  void _sendAuth() => _sendRaw(jsonEncode({'op': 'auth', 'token': _pairingToken}));

}