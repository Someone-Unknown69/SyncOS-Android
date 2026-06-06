import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';

class ProxyConnectionManager implements IConnectionManager {
  final _service = FlutterBackgroundService();
  
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _rawMessageController = StreamController<String>.broadcast();
  
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionConfig? _activeConfig;

  ProxyConnectionManager() {
    _service.on('connection_status').listen((event) {
      if (event != null && event['status'] != null) {
        final statusStr = event['status'] as String;
        final newStatus = ConnectionStatus.values.firstWhere(
          (e) => e.toString() == statusStr, 
          orElse: () => ConnectionStatus.disconnected
        );
        _status = newStatus;
        _statusController.add(newStatus);
      }
      if (event != null && event['config'] != null) {
        _activeConfig = ConnectionConfig.fromMap(Map<String, dynamic>.from(event['config']));
      } else {
        _activeConfig = null;
      }
    });

    _service.on('raw_message').listen((event) {
      if (event != null && event['message'] != null) {
        _rawMessageController.add(event['message'] as String);
      }
    });
    
    // Request initial state from background in case it was already connected
    _service.invoke('request_initial_state');
  }

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;

  @override
  Stream<String> get rawMessageStream => _rawMessageController.stream;

  @override
  ConnectionConfig? get activeConfig => _activeConfig;

  @override
  ConnectionStatus get status => _status;

  @override
  Future<void> connect(ConnectionConfig config) async {
    _service.invoke('connect', {'config': config.toJson()});
  }

  @override
  Future<void> pair(ConnectionConfig config) async {
    _service.invoke('pair', {'config': config.toJson()});
  }

  @override
  void disconnect() {
    _service.invoke('disconnect');
  }

  @override
  void send(String op, String action, Map<String, dynamic> args) {
    _service.invoke('send', {
      'op': op,
      'action': action,
      'args': args,
    });
  }
}
