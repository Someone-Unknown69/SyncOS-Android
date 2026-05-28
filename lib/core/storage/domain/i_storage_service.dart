abstract class IStorageService {
  String? get serverIp;
  int? get serverPort;
  String? get pairingToken;
  bool get hasPaired;
  
  Future<void> setServerIp(String value);
  Future<void> setServerPort(int value);
  Future<void> setPairingToken(String value);
}