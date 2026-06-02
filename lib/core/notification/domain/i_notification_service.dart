
abstract class INotificationService {
  Future<void> init();

  Future<void> showNotification({
    required int id,
    required String title,
    String? body,
    int urgency = 1,
    String icon = 'dialog-information',
  });
  
  void showTransferProgress({
    required int id, 
    required String title, 
    required String body,
    required int progress
  });
  
  Future<void> showErrorNotification({
    required int id, 
    required String title, 
    required String error
  });
  
  Future<void> showTestNotification();
  
  Future<void> dismissNotification(int id);
}