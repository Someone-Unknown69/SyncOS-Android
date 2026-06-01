import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/core/storage/provider/storage_service_provider.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Good Morning !';
  if (hour >= 12 && hour < 17) return 'Good Afternoon !';
  if (hour >= 17 && hour < 21) return 'Good Evening !';
  return 'Good Night !';
}

class GreetingNotifier extends Notifier<String> {
  @override
  String build() => getGreeting();

  void refresh() {
    state = getGreeting();
  }
}

final greetingProvider = NotifierProvider<GreetingNotifier, String>(GreetingNotifier.new);

final autoConnectProvider = Provider<AutoConnectController>((ref) {
  final controller = AutoConnectController(ref);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class AutoConnectController with WidgetsBindingObserver {
  final Ref ref;
  late final StreamSubscription<ConnectionStatus> _connectionStatusSubscription;
  ConnectionStatus _currentConnectionStatus = ConnectionStatus.disconnected;

  AutoConnectController(this.ref) {
    WidgetsBinding.instance.addObserver(this);

    final manager = ref.read(connectionManagerProvider);
    _currentConnectionStatus = manager.status;
    _connectionStatusSubscription = manager.connectionStatusStream.listen((status) {
      _currentConnectionStatus = status;
    });

    // Initial connection attempt on startup
    _handleConnect();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionStatusSubscription.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleConnect();
      ref.read(greetingProvider.notifier).refresh();
    }
  }

  Future<void> _handleConnect() async {
    if (_currentConnectionStatus == ConnectionStatus.connected ||
        _currentConnectionStatus == ConnectionStatus.connecting ||
        _currentConnectionStatus == ConnectionStatus.reconnecting ||
        _currentConnectionStatus == ConnectionStatus.pairing) {
      debugPrint('[Auto Connect] Connection already active, skipping auto-connect');
      return;
    }

    final storage = ref.read(storageServiceProvider);

    final config = await storage.getConnectionConfig();
    final isPaired = await storage.isPaired;

    // Only auto-connect if the app has been paired previously
    // if config is empty it means it has not been paired
    // I sort of added a double check just to be safe
    // it's obv both of them will be same
    // If this is degrading performance and can be removed in future consider removing it

    debugPrint('[Auto Connect] Trying to connect with $isPaired and status=$_currentConnectionStatus');

    if (isPaired && config != null) {
      final connectionManager = ref.read(connectionManagerProvider);
      await connectionManager.connect(config);
    } else {
      debugPrint('[Auto Connect] Not paired or config is null');
    }
  }

  /// Exposed for manual reconnection attempts (e.g. from UI buttons)
  Future<void> manualReconnect() async {
    await _handleConnect();
  }
}
