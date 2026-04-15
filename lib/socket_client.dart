import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';


class SocketClient extends ChangeNotifier{
  // ------------------------------    Class Variables    ---------------------------------------
  Socket? _socket;
  final ValueNotifier<int> connectionStatus = ValueNotifier<int>(0);
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _subscription;

  // Defining where to connect the socket
  SocketClient();
  
  // ----------------------------    Device Information    --------------------------------------
  final ValueNotifier<int> batteryLevel = ValueNotifier<int>(0);
  final ValueNotifier<int> latency = ValueNotifier<int>(0);
  final ValueNotifier<String>  deviceName = ValueNotifier<String>('Unknown');
  final ValueNotifier<bool> isCharging = ValueNotifier<bool>(false);

  final Stopwatch _stopwatch = Stopwatch();

  // ---------------------------------    Getters    -------------------------------------------- 
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;


  // --------------------------------     Methods    --------------------------------------------
  Timer? _timer; // Timer to measure latency

  // Asynchronous method to connect to socket and receive data
  Future<void> connect(String host, int port) async{
    try {
      debugPrint('Connecting....... Waiting for approval');
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));

      connectionStatus.value = 1;
      bool approved = false;

      // For continuously listening to receiving data
      _subscription = _socket!
      .cast<List<int>>()
      .transform(utf8.decoder)
      .listen(
        (String data) {
          final trimmed = data.trim();
          debugPrint("Data recieved: $trimmed");

          if (!approved) {
            if (trimmed == 'ACCEPTED') {
              approved = true;
              connectionStatus.value = 2;
              _stopwatch.reset();
              _stopwatch.start();
              debugPrint('Connection approved by server.');
            } else {
              debugPrint('Connection approval denied or invalid response.');
              disconnect();
            }
            return;
          }

          try {
            final info = jsonDecode(trimmed);
            if (info['type'] == 'status') { // system info
              deviceName.value = info['name'] ?? "Unknown";
              batteryLevel.value = info['battery'] ?? 0;
              isCharging.value = info['isCharging'] ?? false;
              latency.value = _stopwatch.elapsedMilliseconds;
              _stopwatch.reset();
              _stopwatch.start(); // Restart for next measurement
              
              notifyListeners(); 
            } else {
              _messageController.add(info);           // Pushing data in the _messageController pipe
            }
          } catch (e) {
            debugPrint('Error parsing data: $e');
          }
        },
        onError: (e){
          debugPrint('Error : $e');
        },
        onDone: () => disconnect(),
      );

      _socket!.done.then((_) {
        connectionStatus.value = 0;
        _socket = null;
        debugPrint("Connection closed by server.");
      });


    } catch (e) {
      connectionStatus.value = 0;
      debugPrint('Error while connecting to the server $e');

      // Will add a logic to retry for error in connection maybe

    }
  }


  // Method to disconnect the socket
  void disconnect() {
    _timer?.cancel();         // Kill the timer first
    _timer = null;

    _stopwatch.stop();        // Stop the stopwatch

    _subscription?.cancel();  // stop the listener
    _subscription = null;

    _socket?.destroy();       // stop the socket
    _socket = null;
    connectionStatus.value = 0;
  }


  // Method to send data from socket to server
  void send(String str) {
    try {
      if(connectionStatus.value == 2) { // if connection is established only then send
        debugPrint('Sending message: $str');
        if (str == 'PING') {
          _stopwatch.reset();
          _stopwatch.start();
        }
        _socket!.write(str);
        _socket!.flush();
        debugPrint('Message Send!');
      } else {
        debugPrint('Connection is not Established');
      }

    } catch (e) {
      debugPrint('Error occurred while sending $e');
    }
  }

}


