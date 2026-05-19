import 'package:flutter/material.dart';

import 'core/globals.dart';
import 'pages/home/home_screen.dart';
import 'services/pairing_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(RemoteControllerApp(hasPaired: StorageService.hasPaired));
}

class RemoteControllerApp extends StatelessWidget {
  final bool hasPaired;
  const RemoteControllerApp({super.key, required this.hasPaired});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncOS',
      scaffoldMessengerKey: snackbarKey,
      debugShowCheckedModeBanner: false,      // Hides the debug banner
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,            // Forces app to use system mode as theme
      home: hasPaired ? const HomeScreen() : const PairingScreen(),
    );
  }
}