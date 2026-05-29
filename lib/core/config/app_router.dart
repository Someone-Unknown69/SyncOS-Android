import 'package:flutter/material.dart';
import 'app_routes.dart';

import 'package:mobile_controller/pages/home/home_screen.dart';
import 'package:mobile_controller/pages/gamepad/gamepad_screen.dart';
import 'package:mobile_controller/pages/settings/settings.dart';
import 'package:mobile_controller/pages/main_layout/main_layout.dart';
import 'package:mobile_controller/pages/settings/preferences/theme_mode.dart';
import 'package:mobile_controller/features/pairing/ui/pairing_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.gamepad:
        return MaterialPageRoute(builder: (_) => const GamePage());
      case AppRoutes.pairingScreen:
        return MaterialPageRoute(builder: (_) => const PairingScreen());

      case AppRoutes.themeMode:
        return MaterialPageRoute(builder: (_) => const ThemeSettings());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );

    }
  }
}