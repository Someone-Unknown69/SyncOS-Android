import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/device_info.dart';

part 'device_info_notifier.g.dart';

@riverpod
class DeviceInfoNotifier extends _$DeviceInfoNotifier{
  @override
  DeviceInfoState build() => const DeviceInfoState();
  
  void update(String name) => state = DeviceInfoState(name : name);
}
