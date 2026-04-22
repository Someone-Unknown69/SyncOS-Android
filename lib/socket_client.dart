import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'services/socket_processor.dart';

enum SocketConnectionState { disconnected, connecting, connected, reconnecting }

class SocketClient extends ChangeNotifier{
  // ------------------------------    Class Variables    ---------------------------------------
  Socket? _socket;
  final ValueNotifier<SocketConnectionState> connectionStatus = ValueNotifier<SocketConnectionState>(SocketConnectionState.disconnected);
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _subscription;
  
  // socket data processor
  final processor = SocketProcessor();
  
  final BytesBuilder _buffer = BytesBuilder();

  // Connection config
  String? _host;
  int? _port;
  // String? _httpHost; // to pass to processor if needed, but processor gets it from us
  
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  bool _isReconnecting = false;
  int _retryCount = 0;

  // Defining where to connect the socket
  SocketClient();
  
  // ---------------------------     Request send template     ----------------------------------
  Map<String, dynamic> createRequest({
  required String op,
  required String action,
  Map<String, dynamic>? args,
  }) {
    return {
      "op": op,           
      "action": action,   
      "args": {},         
      "id": DateTime.now().millisecondsSinceEpoch, 
    };
  }

  // ----------------------------    Device Information    --------------------------------------
  final ValueNotifier<bool> isCharging = ValueNotifier<bool>(false);

  // ---------------------------------    Getters    -------------------------------------------- 
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // --------------------------------     Methods    --------------------------------------------

  String? _pairingToken;

  Future<void> connect(String host, int port, {int? httpPort, String? token}) async {
    if (connectionStatus.value == SocketConnectionState.connected || connectionStatus.value == SocketConnectionState.connecting) return;

    _host = host;
    _port = port;
    if (httpPort != null) {
      processor.setHttpUrl('http://$host:$httpPort');
    }
    
    if (token != null) {
      _pairingToken = token;
    }

    _attemptConnection();
  }
  
  Future<void> _attemptConnection() async {
    if (_host == null || _port == null) return;
    
    connectionStatus.value = _isReconnecting ? SocketConnectionState.reconnecting : SocketConnectionState.connecting;
    
    try {
      debugPrint('Connecting to $_host:$_port...');
      _socket = await Socket.connect(_host, _port!, timeout: const Duration(seconds: 5));
      _buffer.clear();

      if (_pairingToken != null) {
        sendRaw(jsonEncode({'op': 'auth', 'token': _pairingToken}));
      }

      bool approved = false;

      _subscription = _socket!.listen(
        (List<int> data) {
          _buffer.add(data);
          while (_buffer.length >= 4) {
            final bytes = _buffer.toBytes();
            final length = ByteData.view(bytes.buffer).getUint32(0, Endian.big);
            
            if (bytes.length >= 4 + length) {
              final payload = bytes.sublist(4, 4 + length);
              final jsonString = utf8.decode(payload);
              
              if (!approved) {
                if (jsonString == 'ACCEPTED') {
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
                _handleMessage(jsonString);
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
  
  void _handleMessage(String rawJson) {
    if (rawJson == 'PONG') {
      _pongTimeoutTimer?.cancel();
      return;
    }
    
    try {
      processor.handle(rawJson);
    } catch (e) {
      debugPrint('Data processing error: $e');
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
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (connectionStatus.value == SocketConnectionState.connected) {
        sendRaw('PING');
        _pongTimeoutTimer?.cancel();
        _pongTimeoutTimer = Timer(const Duration(seconds: 5), () {
          debugPrint("Heartbeat timeout. Connection dead.");
          _triggerReconnect();
        });
      }
    });
  }
  
  void _cleanupConnection() {
    _heartbeatTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _socket?.destroy();
    _socket = null;
  }

  // Method to disconnect manually
  void disconnect() {
    _isReconnecting = false;
    _host = null;
    _port = null;
    _cleanupConnection();
    connectionStatus.value = SocketConnectionState.disconnected;
  }

  // Method to send raw string over socket
  void sendRaw(String str) {
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

  void sendJson(Map<String, dynamic> data) {
    sendRaw(jsonEncode(data));
  }
}
