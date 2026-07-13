// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

class AppRoutes {
  
  static const String mainScreen = '/';

  // main page routes
  static const String home = '/home';
  static const String settings = '/settings';
  static const String fileSystem = '/fileSystem';
  static const String pairingScreen = '/pairingScreen';
  static const String setupScreen = '/setupScreen';

  // home screen routes
  static const String gamepad = '$home/gamepad';
  static const String runCommands = '$home/runCommands';
  static const String fileTransfer = '$home/fileTransfer';

  // gamepad page routes
  static const launchGamepad = '$gamepad/launchGamepad';
  static const configureLayout = '$gamepad/configureLayout';
  static const gamepadSettings = '$gamepad/gamepadSettings';

  // settings page routes
  static const String themeMode = '$settings/themeMode';
  static const String connectionDetails = '$settings/connectionDetails';
  static const String aboutScreen = '$settings/aboutScreen';
}