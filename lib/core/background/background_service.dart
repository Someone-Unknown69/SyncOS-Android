import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/background/background_event_bus.dart';
import 'package:mobile_controller/core/handler/provider/service_coordinator_provider.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/core/misc/app_logging.dart';
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
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  BackgroundEventBus.setService(service);
  engineNamespace = 'BACKGROUND';
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

  // Provider container for background isolate
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      connectionManagerProvider.overrideWith((ref) {
        final storage = ref.watch(storageServiceProvider);
        return SocketConnectionManager(storage);
      }),
      
    ],
  );

  final connectionManager = container.read(connectionManagerProvider);
  final storage = container.read(storageServiceProvider);

  final coordinator = container.read(serviceCoordinatorProvider);
  
  // Forward status changes to UI
  connectionManager.connectionStatusStream.listen((status) {
    service.invoke('connection_status', {
      'status': status.toString(),
      'config': connectionManager.serverConfig?.toJson(),
    });

    // set's notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "",
        content: (status == ConnectionStatus.connected) ? 
          "Connected to remote device" : "Not connected to any device"
      );
    }
  });

  // Forward raw messages to UI
  connectionManager.rawMessageStream.listen((msg) {
    service.invoke('raw_message', {'message': msg});
  });
  
  // Forward pairing events to UI
  storage.pairingStream.listen((isPaired) {
    service.invoke('paired_status', {'isPaired': isPaired});
  });

  connectionManager.nearbyDevicesStream.listen((data) {
    service.invoke('device_discovery', {
      'config': data,
    });
  });

  service.on('start').listen((event) {
    connectionManager.start();
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

  service.on('unpair').listen((event) async {
    await connectionManager.unpair();
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
      'config': connectionManager.serverConfig?.toJson(),
    });
    storage.isPaired.then((isPaired) {
      service.invoke('paired_status', {'isPaired': isPaired});
    });
  });

  service.on('stopService').listen((event) {
    coordinator.dispose();
    container.dispose();
  });

  Timer.periodic(const Duration(seconds: 30), (timer) {
    logDebug('Daemon', 'Running');
  });
}


