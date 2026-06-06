import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'syncos_native_platform_interface.dart';

/// An implementation of [SyncosNativePlatform] that uses method channels.
class MethodChannelSyncosNative extends SyncosNativePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('syncos_native');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
