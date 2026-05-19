import 'package:flutter/material.dart';
import '../services/handle_request.dart';
import '../services/socket_client.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

// services
final processor = HandleRequest();
final SocketClient client = SocketClient.instance;

// Permisson handling class for notifications
class PermissonHandler {
  
}
