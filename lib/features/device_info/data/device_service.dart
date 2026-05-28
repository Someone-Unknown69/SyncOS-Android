import '../../../core/hardware/domain/i_device_info_service.dart';
import '../../../core/network/domain/i_connection_manager.dart';

class DeviceService {
  final IConnectionManager _socket;
  final IDeviceInfoService _info;

  DeviceService(this._socket, this._info);

  Future<void> sendDeviceHandshake() async {
    final name = await _info.getDeviceName();
    
    _socket.send("device_info", '', {
      'name': name,
    });
  }
}