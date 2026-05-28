import 'models/media_info.dart';

abstract class IMediaService {
  void init();
  Future<void> sendControlCommand(String action, Map<String, dynamic> args);
  Stream<MediaInfo> get mediaStream;
  void dispose();
}