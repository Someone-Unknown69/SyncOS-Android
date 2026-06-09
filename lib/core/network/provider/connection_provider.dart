import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
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
final connectionManagerProvider = Provider<IConnectionManager>((ref) {
  // In case of changing conenection manager in future, add new connection manger here
  final manager = ProxyConnectionManager();
  
  ref.onDispose(() => manager.disconnect());
  
  return manager;
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.connectionStatusStream;
});

final clientConfigProvider = FutureProvider<ConnectionConfig?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getConnectionConfig();
});

final nearbyDevicesProvider = StreamProvider<(ConnectionConfig, String)>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.nearbyDevicesStream;
});
