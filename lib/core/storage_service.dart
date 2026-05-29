import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  // private constant keys
  static const String _kServerIp = 'server_ip';
  static const String _kServerPort = 'server_port';
  static const String _kPairingToken = 'pairing_token';

  // method to initialize shared prefs
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getters and Setters
  static String? get serverIp => _prefs.getString(_kServerIp);
  static Future<bool> setServerIp(String value) => _prefs.setString(_kServerIp, value);
  static int? get serverPort => _prefs.getInt(_kServerPort);
  static Future<bool> setServerPort(int value) => _prefs.setInt(_kServerPort, value);
  static String? get pairingToken => _prefs.getString(_kPairingToken);
  static Future<bool> setPairingToken(String value) => _prefs.setString(_kPairingToken, value);
  static bool get hasPaired => pairingToken != null;
} 