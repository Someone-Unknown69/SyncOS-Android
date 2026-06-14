// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

enum AppBatteryState { charging, discharging, full, unknown }

abstract class IBatteryInfo {
  Future<int> getLevel();
  Future<bool> isCharging();
  AppBatteryState currentState();
  Stream<(AppBatteryState,int)> get onStateChanged;
}