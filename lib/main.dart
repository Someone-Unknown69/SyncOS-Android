import 'package:flutter/material.dart';

import 'core/globals.dart';
import 'pages/main_layout/main_layout.dart';
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
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: hasPaired ? const MainScreen() : const PairingScreen(),
    );
  }
}