// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/utilities/data/ringtone_service_impl.dart';
import 'package:syncos_android/core/utilities/domain/i_ringtone_service.dart';

import '../domain/i_battery_info.dart';
import '../data/battery_info_impl.dart';
import '../domain/i_device_info.dart';
import '../data/device_info_impl.dart';

// To do 
// - Add more info like RAM and Storage in future updates

final batteryInfoProvider = Provider<IBatteryInfo>((ref) {
  return BatteryInfoImpl();
});

final deviceInfoProvider = Provider<IDeviceInfo>((ref) {
  return DeviceInfoImpl();
});

final ringtoneServiceProvider = Provider<IRingtoneService>((ref) {
  return AndroidRingtoneService();
});