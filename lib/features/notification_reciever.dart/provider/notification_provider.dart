import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/i_notification_receiver.dart';
import '../../../core/network/provider/connection_provider.dart';
import '../data/notification_receiver_impl.dart';

final notificationProvider = Provider<INotificationReceiver>((ref) {
  final connection = ref.watch(connectionManagerProvider); 
  
  final service = NotificationReceiverImpl(connectionManager: connection);
  service.init();
  
  ref.onDispose(() => service.dispose());
  return service;
});