import 'socket_client.dart';
import 'package:flutter/foundation.dart';

class USBControllerService {
  void sendEvent(String buttonName, String action) {
    debugPrint("[Gamepad] Controller $action: $buttonName");
    SocketClient.instance.send(
      "controller",
      action,
      {
        "button" : buttonName,
      }
    );
  }

  void sendAnalog(String analog, double x, double y) {
    debugPrint("[Gamepad] Controller analog $analog: [$x, $y]");
    SocketClient.instance.send(
      "controller", 
      analog, 
      {
        'x' : x,
        'y' : y
      }
    );
  }
}