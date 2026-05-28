abstract class IDeviceInfoService {
  Future<String> getDeviceName();
  Future<String> getOSVersion();
}