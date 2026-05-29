abstract class INotificationListener {
  Future<void> start();
  void stop();
  void dispose();
}