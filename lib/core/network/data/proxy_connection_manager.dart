import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
import 'package:rxdart/rxdart.dart';

class ProxyConnectionManager implements IConnectionManager {
  final _service = FlutterBackgroundService();
  
  final _statusController = BehaviorSubject<ConnectionStatus>.seeded(
    ConnectionStatus.disconnected,
  );
  final _rawMessageController = StreamController<String>.broadcast();

  final _nearbyDevicesController = StreamController<ConnectionConfig>.broadcast();
  
  ConnectionConfig? _serverConfig;

  ProxyConnectionManager() {
    _service.on('connection_status').listen((event) {
      if (event != null && event['status'] != null) {
        final statusStr = event['status'] as String;
        final newStatus = ConnectionStatus.values.firstWhere(
          (e) => e.toString() == statusStr, 
          orElse: () => ConnectionStatus.disconnected
        );

        if (event['config'] != null) {
          _serverConfig = ConnectionConfig.fromMap(Map<String, dynamic>.from(event['config']));
        } else {
          _serverConfig = null;
        }

        _statusController.add(newStatus);
      }  
    });

    _service.on('raw_message').listen((event) {
      if (event != null && event['message'] != null) {
        _rawMessageController.add(event['message'] as String);
      }
    });

    _service.on('device_discovery').listen((event) {
      if (event != null && event['config'] != null) {
        debugPrint("Device discovered with ${event['deviceName']}");
        
        final Map<String, dynamic> configMap = Map<String, dynamic>.from(event['config'] as Map);
        final ConnectionConfig config = ConnectionConfig.fromMap(configMap);
        _nearbyDevicesController.add(config);
      }
    });
    
    // Request initial state from background
    _service.invoke('request_initial_state');
  }

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;

  @override
  Stream<String> get rawMessageStream => _rawMessageController.stream;

  @override
  ConnectionConfig? get serverConfig => _serverConfig;

  @override
  ConnectionStatus get status => _statusController.value;

  @override
  Stream<ConnectionConfig> get nearbyDevicesStream => _nearbyDevicesController.stream;

  @override
  void start() async {
    _service.invoke('start');
  }

  @override 
  void discoverDevices() async {
    _service.invoke('discoverDevices');
  }

  @override
  void stopDiscovery() async {
    _service.invoke('stopDiscovery');
  }

  @override
  Future<void> autoConnectionStart() async {
    _service.invoke('autoConnectionStart');
  }

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

  @override
  Future<void> unpair() async {
    _service.invoke('unpair');
  }

}
