import '../domain/i_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServiceImpl implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> showTransferProgress({
    required int id, 
    required String fileName, 
    required double progress}
  ) async {
    // Logic: Create an AndroidNotificationDetails with setProgress(100, (progress*100).toInt(), false)
  }

  @override
  Future<void> showTransferError({
    required int id, 
    required String fileName, 
    required String error
  }) async {
    // Logic: Simple notification with a red icon or error text
  }

  @override
  Future<void> showTestNotification({
    required String message
  }) async {
    // Logic: Just a basic "Hello World" style notification
  }

  @override
  Future<void> dismissNotification(int id) async {
    await _plugin.cancel(id: id);
  }
}