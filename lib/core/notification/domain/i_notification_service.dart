abstract class INotificationService {
  Future<void> showTransferProgress({required int id, required String fileName, required double progress});
  Future<void> showTransferError({required int id, required String fileName, required String error});
  Future<void> showTestNotification({required String message});
  Future<void> dismissNotification(int id);
}