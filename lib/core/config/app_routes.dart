class AppRoutes {
  
  static const String mainScreen = '/';

  // main page routes
  static const String home = '/home';
  static const String settings = '/settings';
  static const String fileSystem = '/fileSystem';
  static const String pairingScreen = '/pairingScreen';

  // home screen routes
  static const String gamepad = '$home/gamepad';

  // gamepad page routes
  static const launchGampad = '$gamepad/launchGamepad';
  static const configureLayout = '$gamepad/configureLayout';
  static const gamepadSettings = '$gamepad/gamepadSettings';

  // settings page routes
  static const String themeMode = '$settings/themeMode';
  static const String serverConfig = '$settings/serverConfig';
  static const String about = '$settings/about';
  static const String pairNewDevice = '$settings/pairNewDevice';
}