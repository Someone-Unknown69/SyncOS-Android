import 'models/media_info.dart';

abstract class IMediaService {
  Future<void> start();
  void stop();
  Future<void> sendControlCommand(Map<String, dynamic> args);
  Stream<MediaInfo> get mediaStream;
  void dispose();
}