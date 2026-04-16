import 'dart:convert';
import 'package:flutter/foundation.dart';

class SocketProcessor {
  static final SocketProcessor _instance = SocketProcessor._internal();
  factory SocketProcessor() => _instance;
  SocketProcessor._internal() {
    _handlers = {
      "sys_info": _handleStatus,
      "music": _handleMusic,
    };
  }


  // Map of op to the handler functions
  late final Map<String, Function(Map<String, dynamic>)> _handlers;

  // Device Information
  final ValueNotifier<int> batteryLevel = ValueNotifier<int>(0);
  final ValueNotifier<String> deviceName = ValueNotifier<String>("Unknown");
  final ValueNotifier<bool> isCharging = ValueNotifier<bool>(false);
  final ValueNotifier<int> latency = ValueNotifier<int>(0);
  // final Stopwatch stopwatch;
  // Music Information


  void handle(String rawJson) {
    try {
      final data = jsonDecode(rawJson);
      final op = data['op'];

      if (_handlers.containsKey(op)) {
        _handlers[op]!(data);
      } else {
        debugPrint("Unknown operation: $op");
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  // ---------------------------
  // Individual Handler Logics
  // ---------------------------

  void _handleStatus(Map<String, dynamic> data) {
    final args = data['args'];
    debugPrint("$args");
    deviceName.value = args['name'] ?? "Unknown";
    batteryLevel.value = args['battery'] ?? 0;
    isCharging.value = args['isCharging'] ?? false;
    
    // Handle Latency
    // latency.value = stopwatch.elapsedMilliseconds;
    // stopwatch.reset();
    // stopwatch.start();

    debugPrint("Updated: ${deviceName.value} - ${isCharging.value}%");

  }

  void _handleMusic(Map<String, dynamic> data) {
    debugPrint("Processing Music Data...");
    // Update your Music UI here
  }

  // Allow external files (like UI) to inject their own logic
  void registerCallback(String op, Function(Map<String, dynamic>) callback) {
    _handlers[op] = callback;
  }
}