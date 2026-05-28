import '../domain/i_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageServiceImpl implements IStorageService {
  final SharedPreferences _prefs;
  StorageServiceImpl(this._prefs);

  @override 
  String? get serverIp => _prefs.getString('server_ip');

  @override 
  int? get serverPort => _prefs.getInt('server_port');

  @override 
  String? get pairingToken => _prefs.getString('pairing_token');

  @override 
  bool get hasPaired => pairingToken != null;

  @override 
  Future<void> setServerIp(String value) async { await _prefs.setString('server_ip', value); }
  
  @override 
  Future<void> setServerPort(int value) async { await _prefs.setInt('server_port', value); }
  
  @override 
  Future<void> setPairingToken(String value) async { await _prefs.setString('pairing_token', value); }
}