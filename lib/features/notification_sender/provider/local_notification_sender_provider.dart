import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/i_local_notification_sender.dart';
import '../../../core/network/provider/connection_provider.dart';
import '../data/local_notification_sender.dart';

final notificationListeningProvider = Provider<INotificationListener>((ref) {
  final connection = ref.watch(connectionManagerProvider); 
  
  final service = NotificationReceiverImpl(connectionManager: connection);
  service.start();
  
  ref.onDispose(() => service.dispose());
  return service;
});