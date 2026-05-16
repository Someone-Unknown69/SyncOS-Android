import 'dart:async';
import 'package:mobile_controller/socket_client.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:volume_controller/volume_controller.dart';

// -------------------------------      Battery Service      ----------------------------------------
class BatteryMonitorService{
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  StreamSubscription? _batterySubscription;

  Future<int> getBatteryLevel() async => await _battery.batteryLevel;
  Future<BatteryState> getBatteryStatus() async => await _battery.batteryState;

  Future<String> getDeviceName() async {
    AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
    return "${androidInfo.manufacturer} ${androidInfo.model}";
  }

  Future<void> init() async {
    final name = await getDeviceName();
    final level = await getBatteryLevel();
    final status = await getBatteryStatus();

    // send device name + battery info on initial connection
    SocketClient.instance.send("device_info", '', {
      'name': name,
    });

    SocketClient.instance.send("battery_info", '', {
      'level': level,
      'status': status.toString() == 'BatteryState.charging',
    });

    // send battery updates on a subscription
    _batterySubscription?.cancel();
    _batterySubscription = _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final currentLevel = await getBatteryLevel();
      
      final bool isCurrentlyCharging = (state == BatteryState.charging);

      SocketClient.instance.send('battery_info', '', {
        'level': currentLevel,
        'status': isCurrentlyCharging,
      });
    });
  }

  void dispose() {
    _batterySubscription?.cancel();
    _batterySubscription = null;
  }
}


// -------------------------------      Volume Service      ----------------------------------------

class VolumeMonitorService {
  Future<double> getCurrentVolume() async => await VolumeController().getVolume();
  void listenToVolume(Function(double) onVolumeChanged) {
    VolumeController().listener((volume) {
      onVolumeChanged(volume);
    });
  }

  void setVolume(double value) => VolumeController().setVolume(value);

}