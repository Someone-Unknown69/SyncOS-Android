import 'package:flutter/material.dart';
import 'package:mobile_controller/pages/gamepad/gamepad_page.dart';
import 'package:mobile_controller/pages/setup_screen/setup_screen.dart';
import 'app_routes.dart';

import 'package:mobile_controller/pages/home/home_screen.dart';
import 'package:mobile_controller/pages/gamepad/launch_gamepad.dart';
import 'package:mobile_controller/pages/settings/settings.dart';
import 'package:mobile_controller/pages/main_layout/main_layout.dart';
import 'package:mobile_controller/pages/settings/preferences/theme_mode_page.dart';
import 'package:mobile_controller/pages/setup_screen/pairing_screen.dart';

class AppRouter {
  static bool _isNavigating = false;

  static void pushRoute(BuildContext context, String routeName) {
    debugPrint("Attempting to navigate to: $routeName and $_isNavigating");
    if(_isNavigating) return;
    
    _isNavigating = true;

    Navigator.of(context).pushNamed(routeName).catchError((e) {
      debugPrint("Navigation error: $e");
      return null;
    });

    // Reset the flag after the transition animation completes (400ms)
    // to prevent double taps but allow navigation on the new page.
    Future.delayed(const Duration(milliseconds: 400), () {
      _isNavigating = false;
    });
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case AppRoutes.home:
        return _createSlideRoute(const HomeScreen());
      case AppRoutes.settings:
        return _createSlideRoute(const SettingsScreen());
      case AppRoutes.gamepad:
        return _createSlideRoute(const GamepadPage());
      case AppRoutes.pairingScreen:
        return _createSlideRoute(const PairingScreen());
      case AppRoutes.setupScreen:
        return _createSlideRoute(const SetupScreen());

      case AppRoutes.themeMode:
        return _createSlideRoute(const ThemeModePage());

      case AppRoutes.launchGamepad:
        return _createSlideRoute(const LaunchGamepad());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );

    }
  }

  // Sliding Animation
  static Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); 
        const end = Offset.zero;       
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}