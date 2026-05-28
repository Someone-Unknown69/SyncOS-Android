abstract class INotificationReceiver {
  Future<void> init();
  Future<void> dispose();
}