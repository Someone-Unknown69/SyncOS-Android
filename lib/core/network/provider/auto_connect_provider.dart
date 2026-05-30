import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/storage_service.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';

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

  AutoConnectController(this.ref) {
    WidgetsBinding.instance.addObserver(this);
    // Initial connection attempt on startup
    _handleConnect();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleConnect();
      ref.read(greetingProvider.notifier).refresh();
    }
  }

  Future<void> _handleConnect() async {
    // Only auto-connect if the app has been paired previously
    if (!StorageService.hasPaired) return;

    final ip = StorageService.serverIp;
    final port = StorageService.serverPort;
    final token = StorageService.pairingToken;

    if (ip != null && port != null) {
      final connectionManager = ref.read(connectionManagerProvider);
      final config = TcpConfig(host: ip, port: port);
      await connectionManager.connect(config, token: token);
    }
  }

  /// Exposed for manual reconnection attempts (e.g. from UI buttons)
  Future<void> manualReconnect() async {
    await _handleConnect();
  }
}
