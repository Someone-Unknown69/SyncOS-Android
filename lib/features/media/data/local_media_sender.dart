// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:syncos_android/core/media/domain/i_local_media_info.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import '../domain/models/media_info.dart';

// If the state hasn't meaningfully changed, it drops the packet at the service level.
// The StreamController.broadcast ensures that if we decide to hook in multiple
// All the caching happens here

class LocalMediaSender {
  final IConnectionManager _connectionManager;
  final ILocalMediaInfo _localMediaInfo;

  StreamSubscription<MediaInfo>? _subscription;

  MediaInfo _mediaCache = MediaInfo.empty;
  int _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

  LocalMediaSender(this._connectionManager, this._localMediaInfo);

Future<void> start() async {
    logDebug('Local Media Sender', 'Starting');
    await stop();

    _subscription = _localMediaInfo.metadataStream.listen((info) {
      _processMap(info);
    });

    await _localMediaInfo.start();
  }
  void _processMap(MediaInfo newMetadata) {
    final int duration = (newMetadata.duration ?? 0);
    if (duration <= 0 && newMetadata.isValid) return;

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

        if (_isNotSignificantChange(newPos)) {
          return;
        }
      }
    }

    _mediaCache = _mediaCache.mergeWith(newMetadata);

    logDebug('Media Cache', 'Sending payload : ${changedInfo.toMap()}');
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

  void handleControlCommand(Map<String, dynamic> args) {
    _localMediaInfo.control(args);
  }

  Future<void> stop() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }

    _mediaCache = MediaInfo.empty;
    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

    _localMediaInfo.stop();
  }

  Future<void> dispose() async {
    await stop();
    _localMediaInfo.dispose();
  }
}
