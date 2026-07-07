// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:syncos_android/core/config/app_router.dart';
import 'package:syncos_android/core/config/app_routes.dart';
import 'package:syncos_android/pages/components/base_page.dart';
import 'package:syncos_android/pages/components/setting_components.dart';

class GamepadPage extends StatelessWidget {
  const GamepadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Gamepad',
      children: [
        const SectionHeader(title: 'Play time !'),

        SettingsTile(
          icon: Icons.sports_esports, 
          title: "Launch Gamepad", 
          onTap: () {
            AppRouter.pushRoute(context, AppRoutes.launchGamepad);
          },
        ),

        const SectionHeader(title: 'Options'),

        SettingsTile(
          icon: Icons.settings_overscan_rounded,
          title: 'Configure Layout',
          subtitle: 'Change button positions and size',
          onTap: () {
            AppRouter.pushRoute(context, AppRoutes.configureLayout);
          },
        ),

        SettingsTile(
          icon: Icons.settings,
          title: 'Gamepad Settings',
          subtitle: 'Change style, latency etc',
          onTap: () {
            AppRouter.pushRoute(context, AppRoutes.gamepadSettings);
          },
        ),
      ],
    );
  }
}

