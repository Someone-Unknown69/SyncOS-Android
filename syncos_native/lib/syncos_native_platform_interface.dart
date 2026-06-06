import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'syncos_native_method_channel.dart';

abstract class SyncosNativePlatform extends PlatformInterface {
  /// Constructs a SyncosNativePlatform.
  SyncosNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static SyncosNativePlatform _instance = MethodChannelSyncosNative();

  /// The default instance of [SyncosNativePlatform] to use.
  ///
  /// Defaults to [MethodChannelSyncosNative].
  static SyncosNativePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SyncosNativePlatform] when
  /// they register themselves.
  static set instance(SyncosNativePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
