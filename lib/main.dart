import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/background/background_service.dart';
import 'package:mobile_controller/core/notification/data/notification_service_impl.dart';
import 'package:mobile_controller/core/notification/provider/notification_provider.dart';
import 'package:mobile_controller/theme/provider/theme_provider.dart';

import 'core/config/app_router.dart';
import 'theme/app_theme.dart';
import 'pages/main_layout/main_layout.dart';
import 'pages/setup_screen/setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/provider/storage_service_provider.dart';
import 'core/handler/provider/command_dispatcher_provider.dart';

// Requests battery optimization exemption once. Without this, aggressive OEM
// devices (Realme/OPPO/Xiaomi) will kill the background service when the screen
// turns off, even if a foreground service notification is shown.
Future<void> _requestBatteryOptimizationExemption() async {
  try {
    const platform = MethodChannel('android_channel');
    await platform.invokeMethod('requestBatteryOptimization');
  } catch (_) {
  }
}

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initalizeBackgroundServices();
  await _requestBatteryOptimizationExemption();

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


class RemoteControllerApp extends ConsumerStatefulWidget {
  const RemoteControllerApp({super.key});

  @override
  ConsumerState<RemoteControllerApp> createState() => _RemoteControllerAppState();
}

class _RemoteControllerAppState extends ConsumerState<RemoteControllerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commandDispatcherProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
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