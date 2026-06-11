abstract class ICommandDispatcher {
  void start();
  void stop();
  void dispatchCommand({required String operation, required String action, required Map<String, dynamic> args});
}