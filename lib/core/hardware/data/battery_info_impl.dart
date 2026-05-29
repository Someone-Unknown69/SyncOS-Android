import '../domain/i_battery_info.dart';
import 'package:battery_plus/battery_plus.dart';

class BatteryInfoImpl implements IBatteryInfo {
  final Battery _battery = Battery();

  @override
  Future<int> getLevel() => _battery.batteryLevel;

  @override
  Future<bool> isCharging() async => (await _battery.batteryState) == BatteryState.charging;

  @override
  Stream<AppBatteryState> get onStateChanged {
    return _battery.onBatteryStateChanged.map((nativeState) {
      switch (nativeState) {
        case BatteryState.charging:
          return AppBatteryState.charging;
        case BatteryState.discharging:
          return AppBatteryState.discharging;
        case BatteryState.full:
          return AppBatteryState.full;
        default:
          return AppBatteryState.unknown;
      }
    });
  }
}