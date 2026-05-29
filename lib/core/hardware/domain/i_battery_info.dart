enum AppBatteryState { charging, discharging, full, unknown }

abstract class IBatteryInfo {
  Future<int> getLevel();
  Future<bool> isCharging();
  Stream<AppBatteryState> get onStateChanged;
}