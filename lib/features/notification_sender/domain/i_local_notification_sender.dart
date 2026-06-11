abstract class INotificationListener {
  Future<void> start();
  Future<void> stop();
}