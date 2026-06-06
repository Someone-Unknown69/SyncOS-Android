
import 'syncos_native_platform_interface.dart';

class SyncosNative {
  Future<String?> getPlatformVersion() {
    return SyncosNativePlatform.instance.getPlatformVersion();
  }
}
