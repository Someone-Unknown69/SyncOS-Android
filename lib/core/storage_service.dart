import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  // private constant keys
  static const String _kServerIp = 'server_ip';
  static const String _kServerPort = 'server_port';
  static const String _kPairingToken = 'pairing_token';

  // Theme preferences
  static const String _kThemeModeIndex = 'theme_mode_index';
  static const String _kSeedColorValue = 'seed_color_value';

  // method to initialize shared prefs
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme mode (Stored as an integer index of an enum)
  static int? get themeModeIndex => _prefs.getInt(_kThemeModeIndex);
  static Future<bool> setThemeModeIndex(int value) => _prefs.setInt(_kThemeModeIndex, value);

  // Seed Color (stored as an integer value)
  static int? get seedColorValue => _prefs.getInt(_kSeedColorValue);
  static Future<bool> setSeedColorValue(int value) => _prefs.setInt(_kSeedColorValue, value);

  // Getters and Setters
  static String? get serverIp => _prefs.getString(_kServerIp);
  static Future<bool> setServerIp(String value) => _prefs.setString(_kServerIp, value);
  static int? get serverPort => _prefs.getInt(_kServerPort);
  static Future<bool> setServerPort(int value) => _prefs.setInt(_kServerPort, value);
  static String? get pairingToken => _prefs.getString(_kPairingToken);
  static Future<bool> setPairingToken(String value) => _prefs.setString(_kPairingToken, value);
  static bool get hasPaired => serverIp != null && serverPort != null;
} 