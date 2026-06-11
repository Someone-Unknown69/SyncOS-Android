import 'dart:async';
import 'dart:convert';
import 'package:mobile_controller/core/background/background_event_bus.dart';
import 'package:mobile_controller/core/handler/domain/i_command_dispatcher.dart';
import 'package:mobile_controller/core/misc/app_logging.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';

class CommandDispatcher implements ICommandDispatcher {
  final IConnectionManager _connectionManager;

  StreamSubscription<String>? _rawMessageSubscription;
  bool _isStarted = false;

  CommandDispatcher(this._connectionManager) {
    logDebug('Command Dispatcher', 'Instance created');
  }

  @override
  void start() {
    if (_isStarted) return;
    _isStarted = true;
    logDebug('Command Dispatcher', 'Service started and listening for network messages');

    _rawMessageSubscription = _connectionManager.rawMessageStream.listen((rawMessage) {
      try {
        final Map<String, dynamic> data = jsonDecode(rawMessage);
        
        _handleOperation(data);

        logDebug('Command Dispatcher', 'Recieved : $data');

        BackgroundEventBus.emit('update_ui_event', {
          'operation': data['op'],
          'action': data['action'],
          'args': data['args'],
        });
      } catch (e) {
        logDebug('Command Dispatcher', 'Failed to process message: $e');
      }
    });
  }

  void _handleOperation(Map<String, dynamic> data) {
    // NO BACKGROUND SERVICES TO TAKE CARE OF NOW
  }

  @override
  void dispatchCommand({required String operation, required String action, required Map<String, dynamic> args}) {
    // This method is intended for sending commands TO the network
    _connectionManager.send(operation, action, args);
  }

  @override
  void stop() {
    logDebug('Command Dispatcher', 'Stopping listener');
    _rawMessageSubscription?.cancel();
    _rawMessageSubscription = null;
    _isStarted = false;
  }
}