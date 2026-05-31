import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/notification/data/notification_service_impl.dart';
import 'package:mobile_controller/core/notification/provider/notification_provider.dart';
import 'package:mobile_controller/theme/provider/theme_provider.dart';

import 'core/config/app_router.dart';
import 'core/globals.dart';
import 'core/handler/provider/command_dispatcher_provider.dart';
import 'core/network/provider/connection_provider.dart';
import 'core/handler/provider/service_coordinator_provider.dart';
import 'theme/app_theme.dart';
import 'pages/main_layout/main_layout.dart';
import 'pages/setup_screen/setup_screen.dart';
import 'core/network/provider/auto_connect_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/provider/storage_service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationServiceImpl();
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const RemoteControllerApp(),
    ),
  );
}


class RemoteControllerApp extends ConsumerWidget {
  const RemoteControllerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // listeners / init() calls are registered at app start.
    ref.watch(autoConnectProvider);           // Handles auto-connect on startup/resume
    ref.watch(connectionManagerProvider);     // Connection manager
    ref.watch(serviceCoordinatorProvider);    // Orchestrates background services
    ref.watch(commandDispatcherProvider);     // routes rawMessageStream -> state
    
    final themeSettings = ref.watch(themeProvider);
    final paired = ref.watch(pairedProvider);

    Widget homeWidget = paired.when(
      data: (hasPaired) => hasPaired ? const MainScreen() : const SetupScreen(),
      loading: () => const MainScreen(),
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