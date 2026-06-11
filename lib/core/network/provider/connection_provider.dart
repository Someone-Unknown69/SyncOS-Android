import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/network/data/socket_connection_manager.dart';
import 'package:mobile_controller/core/network/domain/connection_config.dart';
import 'package:mobile_controller/core/storage/provider/storage_service_provider.dart';
import '../domain/i_connection_manager.dart';

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
  final storage = ref.watch(storageServiceProvider);
  // In case of changing conenection manager in future, add new connection manger here
  final manager = SocketConnectionManager(storage);
  
  ref.onDispose(() => manager.disconnect());
  
  return manager;
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.connectionStatusStream;
});

final nearbyDevicesProvider = StreamProvider<ConnectionConfig>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.nearbyDevicesStream;
});
