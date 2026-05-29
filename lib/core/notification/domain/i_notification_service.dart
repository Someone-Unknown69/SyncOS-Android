
abstract class INotificationService {
  Future<void> init();
  
  Future<void> showTransferProgress({
    required int id, 
    required String title, 
    required String body,
    required int progress
  });
  
  Future<void> showTransferError({
    required int id, 
    required String title, 
    required String error
  });
  
  Future<void> showTestNotification({
    required int id,
    required String title,
    required String body,
  });
  
  Future<void> dismissNotification(int id);
}