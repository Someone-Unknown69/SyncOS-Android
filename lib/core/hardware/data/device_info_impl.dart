import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../domain/i_device_info.dart';

class DeviceInfoImpl implements IDeviceInfo {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return "${androidInfo.manufacturer} ${androidInfo.model}";
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return "Unknown Device";
  }

  @override
  Future<String> getOSVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      // Returns the Android SDK version (e.g., 34 for Android 14)
      return "Android ${androidInfo.version.release}";
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return "iOS ${iosInfo.systemVersion}";
    }
    return "Unknown OS";
  }
}