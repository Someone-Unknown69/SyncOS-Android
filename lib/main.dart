import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/notification/data/notification_service_impl.dart';
import 'package:mobile_controller/core/notification/provider/notification_provider.dart';
import 'package:mobile_controller/theme/theme_notifier.dart';

import 'core/config/app_router.dart';
import 'core/config/app_routes.dart';
import 'core/globals.dart';
import 'core/handler/provider/command_dispatcher_provider.dart';
import 'core/network/provider/connection_provider.dart';
import 'core/handler/provider/service_coordinator_provider.dart';
import 'core/storage_service.dart';
import 'theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  
  final notificationService = NotificationServiceImpl();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: RemoteControllerApp(),
    ),
  );
}

class RemoteControllerApp extends ConsumerWidget {
  const RemoteControllerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // listeners / init() calls are registered at app start.
    ref.watch(connectionManagerProvider);     // Connection manager
    ref.watch(serviceCoordinatorProvider);    // Orchestrates background services
    ref.watch(commandDispatcherProvider);     // routes rawMessageStream -> state
    final themeSettings = ref.watch(themeProvider);

    final bool hasPaired = StorageService.hasPaired;

    return MaterialApp(
      title: 'SyncOS',
      scaffoldMessengerKey: snackbarKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, themeSettings.seedColor),
      darkTheme: buildTheme(Brightness.dark, themeSettings.seedColor),
      themeMode: themeSettings.themeMode,

      initialRoute: hasPaired ? AppRoutes.mainScreen : AppRoutes.pairingScreen, 
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}