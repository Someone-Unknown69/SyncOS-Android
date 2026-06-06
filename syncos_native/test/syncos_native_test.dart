import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_native/syncos_native.dart';
import 'package:syncos_native/syncos_native_platform_interface.dart';
import 'package:syncos_native/syncos_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSyncosNativePlatform
    with MockPlatformInterfaceMixin
    implements SyncosNativePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SyncosNativePlatform initialPlatform = SyncosNativePlatform.instance;

  test('$MethodChannelSyncosNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSyncosNative>());
  });

  test('getPlatformVersion', () async {
    SyncosNative syncosNativePlugin = SyncosNative();
    MockSyncosNativePlatform fakePlatform = MockSyncosNativePlatform();
    SyncosNativePlatform.instance = fakePlatform;

    expect(await syncosNativePlugin.getPlatformVersion(), '42');
  });
}
