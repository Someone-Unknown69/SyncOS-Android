// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:syncos_android/pages/gamepad/gamepad_page.dart';
import 'package:syncos_android/pages/run_command/command_page.dart';
import 'package:syncos_android/pages/settings/about/about_screen.dart';
import 'package:syncos_android/pages/settings/connection/connection_details.dart';
import 'package:syncos_android/pages/setup_screen/setup_screen.dart';
import 'app_routes.dart';

import 'package:syncos_android/pages/home/home_screen.dart';
import 'package:syncos_android/pages/gamepad/launch_gamepad.dart';
import 'package:syncos_android/pages/gamepad/configure_gamepad.dart';
import 'package:syncos_android/pages/gamepad/gamepad_settings.dart';
import 'package:syncos_android/pages/settings/settings.dart';
import 'package:syncos_android/pages/main_layout/main_layout.dart';
import 'package:syncos_android/pages/settings/preferences/theme_mode_page.dart';
import 'package:syncos_android/pages/setup_screen/pairing_screen.dart';

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
      case AppRoutes.runCommands:
        return _createSlideRoute(const CommandScreen());

      case AppRoutes.themeMode:
        return _createSlideRoute(const ThemeModePage());

      case AppRoutes.launchGamepad:
        return _createSlideRoute(const LaunchGamepad());
      case AppRoutes.configureLayout:
        return _createSlideRoute(const ConfigureGamepadLayout());
      case AppRoutes.gamepadSettings:
        return _createSlideRoute(const GamepadSettingsPage());

      case AppRoutes.connectionDetails:
        return _createSlideRoute(const ConnectionDetails());
      case AppRoutes.aboutScreen:
        return _createSlideRoute(const  AboutScreen());
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