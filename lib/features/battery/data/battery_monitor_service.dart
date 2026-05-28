import '../../../core/hardware/domain/i_battery_service.dart';
import '../../../core/network/domain/i_connection_manager.dart';

class BatteryMonitorService {
  final IConnectionManager _socket;
  final IBatteryService _battery;

  BatteryMonitorService(this._socket, this._battery);

  Future<void> init() async {
    _socket.send("battery_info", '', {
      'level': await _battery.getLevel(),
      'status': await _battery.isCharging(),
    });

    _battery.onStateChanged.listen((state) async {
       _socket.send('battery_info', '', {
        'level': await _battery.getLevel(),
        'status': await _battery.isCharging(),
      });
    });
  }
}