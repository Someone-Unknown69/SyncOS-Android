import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/handler/provider/service_coordinator_provider.dart';
import 'package:mobile_controller/core/network/provider/auto_connect_provider.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_controller/core/storage/provider/storage_service_provider.dart';
import 'package:mobile_controller/core/network/data/socket_connection_manager.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
import 'dart:async';
Future<void> initalizeBackgroundServices() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'syncos_background_service',
      initialNotificationTitle: 'SyncOS',
      initialNotificationContent: 'Running in background...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      // onBackground: onIosBackground
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  if (service is AndroidServiceInstance) {
    // Promote to foreground IMMEDIATELY so Android doesn't kill it when screen turns off
    service.setAsForegroundService();

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
  
  final storageContainer = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  final storage = storageContainer.read(storageServiceProvider);
  final realConnectionManager = SocketConnectionManager(storage);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      connectionManagerProvider.overrideWithValue(realConnectionManager),
    ],
  );

  final connectionManager = container.read(connectionManagerProvider);
  
  // Forward status changes to UI
  connectionManager.connectionStatusStream.listen((status) {
    service.invoke('connection_status', {
      'status': status.toString(),
      'config': connectionManager.activeConfig?.toJson(),
    });
  });

  // Forward raw messages to UI
  connectionManager.rawMessageStream.listen((msg) {
    service.invoke('raw_message', {'message': msg});
  });
  
  // Forward pairing events to UI
  storage.pairingStream.listen((isPaired) {
    service.invoke('paired_status', {'isPaired': isPaired});
  });

  // Listen to UI commands
  service.on('connect').listen((event) {
    if (event != null && event['config'] != null) {
      connectionManager.connect(ConnectionConfig.fromMap(Map<String, dynamic>.from(event['config'])));
    }
  });

  service.on('pair').listen((event) {
    if (event != null && event['config'] != null) {
      connectionManager.pair(ConnectionConfig.fromMap(Map<String, dynamic>.from(event['config'])));
    }
  });

  service.on('disconnect').listen((event) {
    connectionManager.disconnect();
  });

  service.on('send').listen((event) {
    if (event != null) {
      connectionManager.send(
        event['op'] as String,
        event['action'] as String,
        Map<String, dynamic>.from(event['args'] as Map),
      );
    }
  });
  
  service.on('request_initial_state').listen((event) {
    service.invoke('connection_status', {
      'status': connectionManager.status.toString(),
      'config': connectionManager.activeConfig?.toJson(),
    });
    storage.isPaired.then((isPaired) {
      service.invoke('paired_status', {'isPaired': isPaired});
    });
  });

  // IMPORTANT: coordinator must be initialized BEFORE autoConnect so it is already
  // subscribed to connectionStatusStream when the connection attempt fires 'connected'.
  // If autoConnect fires first, the 'connected' event can arrive before coordinator
  // has subscribed and services will never start.
  container.read(serviceCoordinatorProvider);
  container.read(autoConnectProvider);

  // DEBUG: Print a message every 5 seconds to prove the isolate is alive
  Timer.periodic(const Duration(seconds: 5), (timer) {
    debugPrint('[BACKGROUND ISOLATE] Service is currently running at Time: ${DateTime.now()}');
  });
}


