enum AppBatteryState { charging, discharging, full, unknown }

abstract class IBatteryService {
  Future<int> getLevel();
  Future<bool> isCharging();
  Stream<AppBatteryState> get onStateChanged;
}