import 'package:device_info_plus/device_info_plus.dart';
import 'package:mobile_controller/core/utils/app_logging.dart';
import 'dart:io';
import '../domain/i_device_info.dart';

class DeviceInfoImpl implements IDeviceInfo {
  DeviceInfoPlugin? _deviceInfo;

  DeviceInfoPlugin get deviceInfo {
    if (_deviceInfo == null) {
      logDebug('Device Info', 'Initalizing');
      _deviceInfo = DeviceInfoPlugin();
    }
    return _deviceInfo!;
  }

  @override
  Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.manufacturer} ${androidInfo.model}";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return "Unknown Device";
  }

  @override
  Future<String> getOSVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Returns the Android SDK version
      return "Android ${androidInfo.version.release}";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return "iOS ${iosInfo.systemVersion}";
    }
    return "Unknown OS";
  }
}