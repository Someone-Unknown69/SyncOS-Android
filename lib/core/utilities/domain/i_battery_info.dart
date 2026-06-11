enum AppBatteryState { charging, discharging, full, unknown }

abstract class IBatteryInfo {
  Future<int> getLevel();
  Future<bool> isCharging();
  AppBatteryState currentState();
  Stream<(AppBatteryState,int)> get onStateChanged;
}