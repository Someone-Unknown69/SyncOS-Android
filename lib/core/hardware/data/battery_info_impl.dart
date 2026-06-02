import 'dart:async';

import '../domain/i_battery_info.dart';
import 'package:battery_plus/battery_plus.dart';

class BatteryInfoImpl implements IBatteryInfo {
  final Battery _battery = Battery();

  @override
  Future<int> getLevel() => _battery.batteryLevel;

  @override
  Future<bool> isCharging() async => (await _battery.batteryState) == BatteryState.charging;

  @override
  AppBatteryState currentState() => _lastState ?? AppBatteryState.unknown;

  @override
  Stream<(AppBatteryState, int)> get onStateChanged => _controller.stream;

  AppBatteryState? _lastState;
  int? _lastLevel;


  late final StreamController<(AppBatteryState, int)> _controller;

  
  StreamSubscription<BatteryState>? _nativeSub;
  Timer? _pollTimer;
  int _listenerCount = 0;

  BatteryInfoImpl() {
    _controller = StreamController<(AppBatteryState, int)>.broadcast(
      onListen: () {
        _listenerCount++;
        if (_listenerCount == 1) {
          _startSubscriptions();
        }
      },
      onCancel: () {
        _listenerCount--;
        if (_listenerCount <= 0) {
          _stopSubscriptions();
        }
      },
    );
  }

  void _startSubscriptions() {
    // emit initial reading
    () async {
      try {
        final native = await _battery.batteryState;
        final level = await _battery.batteryLevel;
        final state = _mapState(native);
        _lastState = state;
        _lastLevel = level;
        _controller.add((state, level));
      } catch (_) {}
    }();

    // Listen to native state changes and emit (state, level)
    _nativeSub = _battery.onBatteryStateChanged.listen((native) async {
      try {
        final state = _mapState(native);
        _lastState = state;
        final level = await _battery.batteryLevel;
        _lastLevel = level;
        _controller.add((state, level));
      } catch (_) {}
    });

    // Poll for level changes (battery_plus doesn't provide level stream)
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final level = await _battery.batteryLevel;
        if (_lastLevel != level) {
          _lastLevel = level;
          final state = _lastState ?? _mapState(await _battery.batteryState);
          _lastState = state;
          _controller.add((state, level));
        }
      } catch (_) {
        // ignore polling errors
      }
    });
  }

  void _stopSubscriptions() {
    _nativeSub?.cancel();
    _nativeSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  AppBatteryState _mapState(BatteryState nativeState) {
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
  }

}