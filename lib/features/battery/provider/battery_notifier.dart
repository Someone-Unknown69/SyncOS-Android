import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/battery_state.dart';

part 'battery_notifier.g.dart';

@riverpod
class BatteryNotifier extends _$BatteryNotifier {
  @override
  BatteryState build() => const BatteryState();
  
  void update(int level, bool charging) => state = BatteryState(level: level, isCharging: charging);
}
