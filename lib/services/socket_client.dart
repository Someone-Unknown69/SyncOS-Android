import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'handle_request.dart';
import 'music.dart';
import 'device_info.dart';

enum SocketConnectionState { disconnected, connecting, connected, reconnecting }

// ------------------------------     Socket Class     -------------------------------------------------

class SocketClient extends ChangeNotifier{
  // Private constructor
  SocketClient._internal();
  static final SocketClient instance = SocketClient._internal();

  // ------------------------------    Class Variables    ---------------------------------------
  Socket? _socket;
  final ValueNotifier<SocketConnectionState> connectionStatus = ValueNotifier<SocketConnectionState>(SocketConnectionState.disconnected);
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _subscription;
  final BytesBuilder _buffer = BytesBuilder();

  String? _host;
  int? _port;
  
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  bool _isReconnecting = false;
  int _retryCount = 0;

  // Defining where to connect the socket
  SocketClient();

  // --------------------------------     Services       ----------------------------------------
  final batteryMontior = BatteryMonitorService();
  final requestHandler = HandleRequest();
  final music = MediaPoller();

  // ----------------------------    Connection Information    --------------------------------------
  final ValueNotifier<bool> isCharging = ValueNotifier<bool>(false);

  // ---------------------------------    Getters    -------------------------------------------- 
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  String? get serverIP => _host;

  // --------------------------------     Methods    --------------------------------------------

  String? _pairingToken;

  // connect to the server with token
  Future<void> connect(String host, int port, {String? token}) async {
    if (connectionStatus.value == SocketConnectionState.connected || connectionStatus.value == SocketConnectionState.connecting) return;

    _host = host;
    _port = port;
    
    if (token != null) {
      _pairingToken = token;
    }

    _attemptConnection();
    music.init(onSend: send);
    batteryMontior.init();
  }
  
  Future<void> _attemptConnection() async {
    if (_host == null || _port == null) return;
    
    connectionStatus.value = _isReconnecting ? SocketConnectionState.reconnecting : SocketConnectionState.connecting;
    
    try {
      debugPrint('Connecting to $_host:$_port...');
      _socket = await Socket.connect(_host, _port!, timeout: const Duration(seconds: 5));
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      _buffer.clear();

      if (_pairingToken != null) {
        // Send auth directly, sendRaw() requires connectionStatus==connected,
        // but we're still in the 'connecting' state here.
        final authData = utf8.encode(jsonEncode({'op': 'auth', 'token': _pairingToken}));
        final authLength = ByteData(4)..setUint32(0, authData.length, Endian.big);
        _socket!.add(authLength.buffer.asUint8List());
        _socket!.add(authData);
      }

      bool approved = false;

      // Listening to incoming messages
      _subscription = _socket!.listen(
        (List<int> data) {
          _buffer.add(data);
          while (_buffer.length >= 4) {
            final bytes = _buffer.toBytes();
            final length = ByteData.view(bytes.buffer).getUint32(0, Endian.big);
            
            if (bytes.length >= 4 + length) {
              final payload = bytes.sublist(4, 4 + length);
              final rawMessage = utf8.decode(payload);
              
              if (!approved) {
                if (rawMessage == 'ACCEPTED') {
                  approved = true;
                  connectionStatus.value = SocketConnectionState.connected;
                  _isReconnecting = false;
                  _retryCount = 0;
                  _startHeartbeat();
                  debugPrint('Connection accepted.');
                } else {
                  _triggerReconnect();
                }
              } else {
                _handleMessage(rawMessage);
              }
              
              _buffer.clear();
              if (bytes.length > 4 + length) {
                _buffer.add(bytes.sublist(4 + length));
              }
            } else {
              break; // need more data
            }
          }
        },
        onError: (e) {
          debugPrint("Socket error: $e");
          _triggerReconnect();
        },
        onDone: () {
          debugPrint("Connection closed by server.");
          _triggerReconnect();
        },
      );

    } catch (e) {
      debugPrint('Error while connecting: $e');
      _triggerReconnect();
    }
  }

  void _triggerReconnect() {
    _cleanupConnection();
    if (_host == null || _port == null) return;

    _isReconnecting = true;
    connectionStatus.value = SocketConnectionState.reconnecting;
    
    final waitSeconds = min(pow(2, _retryCount).toInt(), 30);
    final jitter = Random().nextDouble() * 1.0;
    final totalWait = waitSeconds + jitter;
    
    debugPrint("Reconnecting in ${totalWait.toStringAsFixed(1)}s...");
    
    Future.delayed(Duration(milliseconds: (totalWait * 1000).toInt()), () {
      if (_isReconnecting) {
        _retryCount++;
        _attemptConnection();
      }
    });
  }
  
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (connectionStatus.value == SocketConnectionState.connected) {
        _sendRaw('PING');
        _pongTimeoutTimer?.cancel();
        _pongTimeoutTimer = Timer(const Duration(seconds: 15), () {
          debugPrint("Heartbeat timeout. Connection dead.");
          _triggerReconnect();
        });
      }
    });
  }

  // Method to disconnect manually
  void handleDisconnect() {
    _isReconnecting = false;
    _host = null;
    _port = null;
    _cleanupConnection();
    connectionStatus.value = SocketConnectionState.disconnected;
  }

  void _cleanupConnection() {
    _heartbeatTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _socket?.destroy();
    _socket = null;

  }

  

  // handling incoming commands
  void _handleMessage(String rawJson) {
    if (rawJson == 'PONG') {
      _pongTimeoutTimer?.cancel();
      return;
    }
    
    try {
      requestHandler.handle(rawJson);
    } catch (e) {
      debugPrint('Data processing error: $e');
    }
  }

  // Method to send raw string over socket
  void _sendRaw(String str) {
    if (connectionStatus.value == SocketConnectionState.connected && _socket != null) {
      try {
        final jsonData = utf8.encode(str);
        final lengthBytes = ByteData(4)..setUint32(0, jsonData.length, Endian.big);
        _socket!.add(lengthBytes.buffer.asUint8List());
        _socket!.add(jsonData);
      } catch (e) {
        debugPrint('Send error: $e');
      }
    }
  }

  // sending commands
  void send(String op, String action, Map<String, dynamic> args) {
    if (_socket == null) return;
    debugPrint("[Socket] Sending '$op' via $_host");

    try {
      final request = {
        "op": op,
        "action": action,
        "args": args,
        "id": DateTime.now().millisecondsSinceEpoch,
      };

      final jsonData = utf8.encode(jsonEncode(request));
      final lengthBytes = ByteData(4)..setUint32(0, jsonData.length, Endian.big);
      
      _socket!.add(lengthBytes.buffer.asUint8List());
      _socket!.add(jsonData);
    } catch (e) {
      debugPrint('Send error: $e');
      handleDisconnect();
    }
  }

}
