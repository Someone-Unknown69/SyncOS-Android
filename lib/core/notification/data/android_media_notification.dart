// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/misc/base64_image_converter.dart';
import 'package:syncos_android/core/notification/domain/i_media_notification.dart';
import 'package:syncos_android/features/music/data/remote_media_service.dart';
import 'package:syncos_android/features/music/domain/models/media_info.dart';

/// Drives the Android MediaStyle notification based on remote media state.
///
/// Lifecycle:
///   start()        — opens the Kotlin EventChannel for button taps and
///                    subscribes to [RemoteMediaService.mediaUpdates].
///   updateNotif()  — serialises [MediaInfo] and pushes it to Kotlin.
///   removeNotif()  — tells Kotlin to cancel the notification.
///   stop()         — tears everything down cleanly.
class AndroidMediaNotification implements IMediaNotification {
  final RemoteMediaService _remoteMediaService;

  static const _method = MethodChannel('com.example.media_notification');
  static const _events = EventChannel('com.example.media_notification/controls');

  bool isDisplayingNotification = false;

  StreamSubscription? _controlSub;
  StreamSubscription? _mediaSub;

  AndroidMediaNotification(this._remoteMediaService);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> start() async {
    // Listen for play/pause/next/previous button taps from the notification
    _controlSub ??= _events.receiveBroadcastStream().listen(
      (event) => _handleControl(event as String),
      onError: (e) => logDebug('Media Notification', 'Control stream error: $e'),
    );

    // Subscribe to remote media state updates
    _mediaSub ??= _remoteMediaService.mediaUpdates.listen((mediaInfo) async {
      if (mediaInfo.isValid) {
        if (!isDisplayingNotification) await displayNotif();
        await updateNotif(mediaInfo);
      } else {
        if (isDisplayingNotification) await removeNotif();
      }
    });

    logDebug('Media Notification', 'Started — listening for media + controls');
  }

  @override
  Future<void> stop() async {
    await _controlSub?.cancel();
    _controlSub = null;
    await _mediaSub?.cancel();
    _mediaSub = null;
    await removeNotif();
    logDebug('Media Notification', 'Stopped');
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  @override
  Future<void> displayNotif() async {
    isDisplayingNotification = true;
    logDebug('Media Notification', 'Displaying notification');
    await _method.invokeMethod('showMediaNotification', {
      'title': '',
      'artist': '',
      'album': '',
      'isPlaying': false,
      'albumArtBase64': null,
      'position': 0,
      'duration': 0,
    });
  }

  @override
  Future<void> updateNotif(MediaInfo mediaInfo) async {
    logDebug('Media Notification', 'Updating → ${mediaInfo.title} [${mediaInfo.status}]');

    // Encode album art as base-64 so Kotlin can decode it from the map
    String? albumArtBase64;
    if (mediaInfo.albumArtUri != null) {
      try {
        albumArtBase64 = await fileToBase64(mediaInfo.albumArtUri!);
      } catch (e) {
        logDebug('Media Notification', 'Album art encode failed: $e');
      }
    }

    await _method.invokeMethod('updateMediaNotification', {
      'title': mediaInfo.title ?? '',
      'artist': mediaInfo.artist ?? '',
      'album': mediaInfo.album ?? '',
      'isPlaying': mediaInfo.status ?? false,
      'albumArtBase64': albumArtBase64,
      // RemoteMediaService stores position/duration in seconds,
      // but Android MediaSession requires milliseconds.
      'position': (mediaInfo.position ?? 0) * 1000,
      'duration': (mediaInfo.duration ?? 0) * 1000,
    });
  }

  @override
  Future<void> removeNotif() async {
    isDisplayingNotification = false;
    logDebug('Media Notification', 'Removing notification');
    await _method.invokeMethod('removeMediaNotification');
  }

  // ── Control routing ────────────────────────────────────────────────────────

  void _handleControl(String control) {
    logDebug('Media Notification', 'Button tapped: $control');
    
    if (control.startsWith('seek:')) {
      final posStr = control.substring(5);
      final pos = int.tryParse(posStr);
      if (pos != null) {
        _remoteMediaService.sendSeek(pos);
      }
      return;
    }

    switch (control) {
      case 'play_pause':
        _remoteMediaService.playPauseToggle();
      case 'next':
        _remoteMediaService.next();
      case 'previous':
        _remoteMediaService.previous();
    }
  }
}
