import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'services/socket_processor.dart';


class SocketClient extends ChangeNotifier{
  // ------------------------------    Class Variables    ---------------------------------------
  Socket? _socket;
  final ValueNotifier<int> connectionStatus = ValueNotifier<int>(0);
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _subscription;
  
  // socket data processor
  final processor = SocketProcessor();

  // Defining where to connect the socket
  SocketClient();
  
  // ---------------------------     Request send template     ----------------------------------
  // This is the template for any request sent to the other device

  Map<String, dynamic> createRequest({
  required String op,
  required String action,
  Map<String, dynamic>? args,
  }) {
    return {
      "op": op,           // Operation type                    
      "action": action,   // action to be taken
      "args": {},         // arguments  
      "id": DateTime.now().millisecondsSinceEpoch, // Sequence number
    };
  }

  // ----------------------------    Device Information    --------------------------------------
  final ValueNotifier<bool> isCharging = ValueNotifier<bool>(false);
  final Stopwatch _stopwatch = Stopwatch();

  // ---------------------------------    Getters    -------------------------------------------- 
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;


  // --------------------------------     Methods    --------------------------------------------

  // Asynchronous method to connect to socket and receive data
  Future<void> connect(String host, int port) async{
    try {
      debugPrint('Connecting....... Waiting for approval');
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));

      connectionStatus.value = 1;
      bool approved = false;


      // For continously recieving data
      _subscription = _socket!
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        (String line) {
          final rawJson = line.trim();
          if(rawJson.isEmpty) return;
          debugPrint("Data recieved: $rawJson");

          if (!approved) {
            if (rawJson == 'ACCEPTED') {
              approved = true;
              connectionStatus.value = 2;
              _stopwatch.reset();
              _stopwatch.start();
            } else {
              disconnect();
            }
            return;
          }

          try {
            processor.handle(rawJson);
          } catch (e) {
            connectionStatus.value = 0;
            debugPrint('Error while connecting to the server $e');
          }
        },
        onError: (e) => debugPrint("Error : $e"),
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
