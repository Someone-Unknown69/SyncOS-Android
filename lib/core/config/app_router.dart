import 'package:flutter/material.dart';
import 'app_routes.dart';

import 'package:mobile_controller/pages/home/home_screen.dart';
import 'package:mobile_controller/pages/gamepad/gamepad_screen.dart';
import 'package:mobile_controller/pages/settings/settings.dart';
import 'package:mobile_controller/pages/main_layout/main_layout.dart';
import 'package:mobile_controller/pages/settings/preferences/theme_mode_page.dart';
import 'package:mobile_controller/features/pairing/ui/pairing_screen.dart';

class AppRouter {
  static bool _isNavigating = false;

  // will ignore the extra taps on navigation buttons
  static void pushRoute(BuildContext context, String routeName) {
    if(_isNavigating) return;

    _isNavigating = true;

    Navigator.of(context).pushNamed(routeName).then((_) {
      _isNavigating = false;
    }).catchError((_) {
      _isNavigating = false;
    });
  }

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
        return _createSlideRoute(const ThemeModePage());

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