import 'socket_client.dart';
import 'package:flutter/foundation.dart';

class USBControllerService {
  void sendEvent(String buttonName, String action) {
    debugPrint("[USB-UI] Controller $action: $buttonName");
    SocketClient.instance.send(
      "controller",
      action,
      {
        "button" : buttonName,
      }
    );
  }
}