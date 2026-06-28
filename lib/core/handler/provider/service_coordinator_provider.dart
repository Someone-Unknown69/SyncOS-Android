// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/background/background_service_provider.dart';
import 'package:syncos_android/core/media/provider/media_notification_provider.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/features/battery/provider/local_battery_sender_provider.dart';
import 'package:syncos_android/features/media/provider/local_media_sender_provider.dart';
import 'package:syncos_android/features/media/provider/remote_media_provider.dart';
import 'package:syncos_android/features/notification_sender/provider/local_notification_sender_provider.dart';
import '../data/service_coordinator.dart';
import 'command_dispatcher_provider.dart';

final serviceCoordinatorProvider = Provider<ServiceCoordinator>((ref) {
  final connectionManager = ref.watch(connectionManagerProvider);
  final batteryService = ref.watch(batteryMonitorProvider);
  final mediaService = ref.watch(mediaSenderProvider);
  final notificationListener = ref.watch(notificationListeningProvider);
  final commandDispatcher = ref.watch(commandDispatcherProvider);
  final remoteMediaService = ref.watch(remoteMediaServiceProvider);
  final mediaNotificationService = ref.watch(mediaNotificationProvider);
  final backgroundService = ref.watch(backgroundServiceProvider);

  final coordinator = ServiceCoordinator(
    connectionManager: connectionManager,
    batteryMonitorService: batteryService,
    mediaService: mediaService,
    notificationListener: notificationListener,
    commandDispatcher: commandDispatcher,
    remoteMediaService: remoteMediaService,
    mediaNotification: mediaNotificationService,
    service: backgroundService,
  );

  ref.onDispose(() => coordinator.dispose());

  return coordinator;
});
