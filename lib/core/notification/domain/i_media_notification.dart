import 'package:syncos_android/features/music/domain/models/media_info.dart';

// This is supposed to take the stream input form remote media service and is fully responsible for it's state
// Highly adviced to implement seperate display and remove notification methods for this

abstract class IMediaNotification {
  Future<void> start();
  Future<void> displayNotif();
  Future<void> removeNotif();
  Future<void> updateNotif(MediaInfo mediaInfo);
  Future<void> stop();
}
