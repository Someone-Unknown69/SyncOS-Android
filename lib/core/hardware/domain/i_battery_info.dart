enum AppBatteryState { charging, discharging, full, unknown }

abstract class IBatteryInfo {
  Future<int> getLevel();
  Future<bool> isCharging();
  Stream<int> get onLevelChanged;
  Stream<AppBatteryState> get onStateChanged;
}