// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import '../domain/i_local_media_sender.dart';
import '../domain/models/media_info.dart';

// The logic here is essentially a data-processing pipeline.
// The service opens a channel to the EventChannel, pipes the raw map data

// If the state hasn't meaningfully changed, it drops the packet at the service level.
// The StreamController.broadcast ensures that if we decide to hook in multiple

class MediaServiceImpl implements IMediaService {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final IConnectionManager _connectionManager;

  StreamSubscription? _musicSubscription;

  MediaInfo _mediaCache = MediaInfo.empty;
  int _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

  MediaServiceImpl({
    required IConnectionManager connectionManager,
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _connectionManager = connectionManager,
       _methodChannel =
           methodChannel ?? const MethodChannel('com.example.music_detection'),
       _eventChannel =
           eventChannel ??
           const EventChannel('com.example.music_detection/events');

  @override
  Future<void> start() async {
    _mediaCache = _mediaCache = MediaInfo.empty;
    logDebug('Media Listener', 'Waking up service');

    try {
      final granted = await _methodChannel.invokeMethod(
        'initializeMusicDetection',
      );
      logDebug('Media Listener', 'initializeMusicDetection granted=$granted');
      _startListening();
    } catch (e) {
      logDebug('Media Listener', 'Failed to initialize platform channels: $e');
    }
  }

  void _startListening() {
    _stopListening();
    _methodChannel.invokeMethod('getCurrentMusicInfo').then((result) {
      if (result != null) _processMap(Map<String, dynamic>.from(result as Map));
    });

    _musicSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) => _processMap(Map<String, dynamic>.from(event as Map)),
    );
  }

  void _processMap(Map<String, dynamic> info) {
    if (info.isEmpty || info['packageName'] == 'com.syncos.syncos_android') {
      return;
    }

    // Initial/Ghost Guard
    final int duration = (info['duration'] as int? ?? 0) ~/ 1000;
    if (duration <= 0) return;

    final newMetadata = MediaInfo.fromMap(info);

    final bool isNewTrack = newMetadata.identity != _mediaCache.identity;

    final changedInfo = newMetadata.calculateDeltaObject(_mediaCache);

    if (changedInfo.isCorrupt) {
      return;
    }

    if (isNewTrack) {
      // Reset the cache media info
      _mediaCache = MediaInfo.empty;
    } else {
      if (changedInfo.position != null &&
          changedInfo.title == null &&
          changedInfo.artist == null &&
          changedInfo.status == null) {
        final int newPos = changedInfo.position!;

        // If the jump is less than or equal to 5000 milliseconds (5 seconds), skip sending
        if (_isNotSignificantChange(newPos)) {
          return;
        }
      }
    }

    _mediaCache = _mediaCache.mergeWith(newMetadata);
    _sendChange(changedInfo);
  }

  bool _isNotSignificantChange(int newPos) {
    final int oldPos = _mediaCache.position ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int elapsed = now - _lastUpdateTime;
    final int predictedPos = (_mediaCache.status == true)
        ? (oldPos + elapsed)
        : oldPos;
    return (predictedPos - newPos).abs() <= 2000;
  }

  void _sendChange(MediaInfo metadata) async {
    logDebug('Media Listener', 'Sending payload : ${metadata.toMap()}');
    final payload = await metadata.toPayload();
    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
    _connectionManager.send('music', 'update_metadata', payload);
    return;
  }

  @override
  Future<void> sendControlCommand(Map<String, dynamic> args) async {
    try {
      final position = args['position'];
      final methodPattern = args['method'];

      if (methodPattern == 'seek') {
        await _methodChannel.invokeMethod('seek', {
          'position': position * 1000,
        });
      }

      final methodMap = {
        'next': 'next',
        'previous': 'previous',
        'play_pause': 'playPause',
      };

      logDebug('Media Listener', "Called method ${methodPattern.toString()}");

      final targetMethod = methodMap[methodPattern];
      if (targetMethod != null) {
        await _methodChannel.invokeMethod(targetMethod);
      }
    } catch (e) {
      throw Exception("Media Control failed: $e");
    }
  }

  @override
  Future<void> stop() async {
    _stopListening();
  }

  @override
  Future<void> dispose() async {
    await stop();
  }

  void _stopListening() {
    _mediaCache = MediaInfo.empty;

    if (_musicSubscription == null) return;
    _musicSubscription?.cancel();
    _musicSubscription = null;
    logDebug('Media Listener', "Music platform channels cleanly detached");
  }
}
