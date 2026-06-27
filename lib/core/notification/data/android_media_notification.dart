import 'dart:async';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/notification/domain/i_media_notification.dart';
import 'package:syncos_android/features/music/data/remote_media_service.dart';
import 'package:syncos_android/features/music/domain/models/media_info.dart';

class AndroidMediaNotification implements IMediaNotification {
  final RemoteMediaService _remoteMediaService;
  bool isDisplayingNotification = false;

  AndroidMediaNotification(this._remoteMediaService);

  @override
  Future<void> start() async {
    _remoteMediaService.mediaUpdates.listen((mediaInfo) async {
      if (mediaInfo.isValid) {
        // initialize if not initalized
        if (!isDisplayingNotification) await displayNotif();
        await updateNotif(mediaInfo);
      } else {
        // is initalized then remove the Notification
        if (isDisplayingNotification) await removeNotif();
      }
    });
  }

  @override
  Future<void> stop() async {
    logDebug('Media Notification','removing Service');
    removeNotif();
  }

  @override
  Future<void> displayNotif() async {
    isDisplayingNotification = true;
    logDebug('Media Notification','displaying Notification');
  }

  @override
  Future<void> updateNotif(MediaInfo mediaInfo) async {
    logDebug('Media Notification','Updating notification ${mediaInfo.toMap()}');
  }

  @override
  Future<void> removeNotif() async {
    isDisplayingNotification = false;
    logDebug('Media Notification','removing notification');
  }

  // listen to controls and forward them to the remote media service
}
