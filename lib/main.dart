// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/background/background_service.dart';
import 'package:syncos_android/core/handler/data/proxy_command_dispatcher.dart';
import 'package:syncos_android/core/handler/provider/command_dispatcher_provider.dart';
import 'package:syncos_android/core/handler/provider/service_coordinator_provider.dart';
import 'package:syncos_android/core/network/data/proxy_connection_manager.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/core/notification/data/notification_service_impl.dart';
import 'package:syncos_android/core/notification/provider/notification_provider.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/features/file_transfer/provider/file_transfer_provider.dart';
import 'package:syncos_android/theme/provider/theme_provider.dart';

import 'core/config/app_router.dart';
import 'theme/app_theme.dart';
import 'pages/main_layout/main_layout.dart';
import 'pages/setup_screen/setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/provider/storage_service_provider.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

// Requests battery optimization exemption once. Without this, aggressive OEM
// devices (Realme/OPPO/Xiaomi) will kill the background service when the screen
// turns off, even if a foreground service notification is shown.
Future<void> _requestBatteryOptimizationExemption() async {
  try {
    const platform = MethodChannel('android_channel');
    await platform.invokeMethod('requestBatteryOptimization');
  } catch (_) {}
}

Future<void> _ensurePermissions() async {
  const channel = MethodChannel('com.example/permissions');
  final bool hasAccess = await channel.invokeMethod(
    'checkNotificationListener',
  );

  if (!hasAccess) {
    await channel.invokeMethod('requestNotificationListener');
    await Future.delayed(const Duration(seconds: 2));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensurePermissions();
  await _requestBatteryOptimizationExemption();

  await initalizeBackgroundServices();

  final notificationService = NotificationServiceImpl();
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();
  engineNamespace = 'MAIN';

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
        commandDispatcherProvider.overrideWith((ref) {
          return ProxyCommandDispatcher(
            ref,
            ref.watch(fileTransferServiceProvider),
          );
        }),
        connectionManagerProvider.overrideWith(
          (ref) => ProxyConnectionManager(),
        ),
        serviceCoordinatorProvider.overrideWith((ref) {
          throw UnimplementedError(
            'The ServiceCoordinator belongs strictly in the background isolate',
          );
        }),
      ],
      child: const RemoteControllerApp(),
    ),
  );
}

class RemoteControllerApp extends ConsumerStatefulWidget {
  const RemoteControllerApp({super.key});

  @override
  ConsumerState<RemoteControllerApp> createState() =>
      _RemoteControllerAppState();
}

class _RemoteControllerAppState extends ConsumerState<RemoteControllerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);
    final paired = ref.watch(pairedProvider);
    ref.watch(commandDispatcherProvider);

    Widget homeWidget = paired.when(
      data: (hasPaired) => hasPaired ? const MainScreen() : const SetupScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SetupScreen(),
    );

    return MaterialApp(
      title: 'SyncOS',
      scaffoldMessengerKey: snackbarKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, themeSettings.seedColor),
      darkTheme: buildTheme(Brightness.dark, themeSettings.seedColor),
      themeMode: themeSettings.themeMode,

      home: homeWidget,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

