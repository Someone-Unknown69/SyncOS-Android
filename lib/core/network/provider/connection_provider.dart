import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/storage/provider/storage_service_provider.dart';
import '../domain/i_connection_manager.dart';
import '../data/proxy_connection_manager.dart';

/// The global access point for connection system.
/// 
/// USAGE:
/// IN UI (Widgets): 
///    Use 'ref.watch(connectionManagerProvider)' to access the instance.
///    - To connect: ref.read(connectionManagerProvider).connect(myConfig);
///    - To observe status: ref.watch(connectionManagerProvider).connectionStatusStream;
///
/// IN BUSINESS LOGIC (Services):
///    Inject 'IConnectionManager' into service constructors.
///    final service = service(ref.read(connectionManagerProvider));
///
/// FUTURE-PROOFING:
///    If in case we decide to switch from TCP to Bluetooth, simply change 
///    'ProxyConnectionManager()' to 'BluetoothConnectionManager()' 
///    right here. The rest of your app requires ZERO changes.

final connectionManagerProvider = Provider<IConnectionManager>((ref) {
  // In case of changing conenection manager in future, ONLY THIS FILE shall be changed
  
  final manager = ProxyConnectionManager();
  
  ref.onDispose(() => manager.disconnect());
  
  return manager;
});