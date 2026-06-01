import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/network/provider/connection_provider.dart';
import 'package:mobile_controller/features/battery/provider/local_battery_sender_provider.dart';
import 'package:mobile_controller/features/music/provider/local_media_sender_provider.dart';
import 'package:mobile_controller/features/notification_sender/provider/local_notification_sender_provider.dart';
import '../data/service_coordinator.dart';
import 'command_dispatcher_provider.dart';

final serviceCoordinatorProvider = Provider<ServiceCoordinator>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  final batteryService = ref.watch(batteryMonitorProvider);
  final mediaService = ref.watch(mediaServiceProvider);
  final notificationListener = ref.watch(notificationListeningProvider);
  final commandDispatcher = ref.watch(commandDispatcherProvider);

  final coordinator = ServiceCoordinator(
    connectionManager: connectionManager,
    batteryMonitorService: batteryService,
    mediaService: mediaService,
    notificationListener: notificationListener,
    commandDispatcher: commandDispatcher,
  );

  ref.onDispose(() => coordinator.dispose());

  return coordinator;
});
