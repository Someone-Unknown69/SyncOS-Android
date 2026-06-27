// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/features/music/domain/i_remote_media_state.dart';
import 'package:syncos_android/features/music/domain/models/media_info.dart';

// This provides remote media updates to both background services as well as UI listeners , the metadata is cached so anyone can request metadata anytime
// Note that this shall be the only source for remote media data as well as control methods
// Also note that this is not supposed to perform any checking of cached things (we are caching for new listeners only) it was aleady supposed to be done on sender side
// Why we are not checking ? What is even going to happen here that already has not happened

class RemoteMediaService implements IRemoteMediaState {
  final IConnectionManager _connectionManager;

  MediaInfo _mediaCache = MediaInfo.empty;
  DateTime? _lastCacheTime;

  final StreamController<MediaInfo> _controller =
      StreamController<MediaInfo>.broadcast();

  ServiceInstance? _backgroundService;

  StreamSubscription? _uiServiceSubscription;
  StreamSubscription? _bgServiceSubscription;

  @override
  MediaInfo get currentState => _mediaCache;

  @override
  Stream<MediaInfo> get mediaUpdates => _controller.stream;

  bool isUiInstance = false;

  RemoteMediaService(this._connectionManager);

  Future<void> start({ServiceInstance? backgroundService}) async {
    try {
      if (backgroundService == null) {
        // UI side setup
        isUiInstance = true;
        await _setUIListeners();
        logDebug('Remote Media', 'Initiated');
      } else {
        // Background isolate setup
        _backgroundService = backgroundService;
        await _setBackgroundListeners();
        logDebug('Remote Media', 'Started background media receiver');
      }
    } catch (e) {
      logDebug('Remote Media', 'Initialization failed $e');
    }
  }

  Future<void> stop() async {
    logDebug('Remote Media', 'Stopping service');

    await _uiServiceSubscription?.cancel();
    await _bgServiceSubscription?.cancel();

    _uiServiceSubscription = null;
    _bgServiceSubscription = null;
    _backgroundService = null;

    await _controller.close();
  }

  void updateMedia(MediaInfo metadata) {
    try {
      // Merges to cache the data
      _mediaCache = _mediaCache.mergeWith(metadata);
      _lastCacheTime = DateTime.now();
      _controller.add(_mediaCache);

      if (!isUiInstance) {
        _backgroundService?.invoke('media_meta_update', _mediaCache.toMap());
      }
    } catch (e) {
      logDebug('Remote Media', 'Update media failed $e');
    }
  }

  void playPauseToggle() {
    _sendSongChange('play_pause');
  }

  void next() {
    _sendSongChange('next');
  }

  void previous() {
    _sendSongChange('previous');
  }

  void sendSeek(int position) {
    _sendSeekChange(position);
  }

  void _sendSongChange(String method) {
    // TODO : Register the native changes here and disable the reconfirmation of control updates

    if (isUiInstance) {
      FlutterBackgroundService().invoke('media_control_command', {
        'method': method,
      });
    } else {
      _connectionManager.send('music', 'control', {'method': method});
    }
  }

  void _sendSeekChange(int position) {
    // Immediately update local cache so the UI and Android Media Notification 
    // seekbars update instantly on both isolates
    final updatedMetadata = _mediaCache.copyWith(
      isValid: _mediaCache.isValid,
      position: position,
    );
    updateMedia(updatedMetadata);

    if (isUiInstance) {
      FlutterBackgroundService().invoke('media_control_command', {
        'position': position,
      });
    } else {
      _connectionManager.send('music', 'control', {'method': 'seek', 'position': position});
    }
  }

  Future<void> _setUIListeners() async {
    await _uiServiceSubscription?.cancel();

    // Setup background metadata listeners
    _uiServiceSubscription = FlutterBackgroundService()
        .on('media_meta_update')
        .listen((message) {
          if (message != null) {
            final incomingMeta = MediaInfo.fromMap(message);
            _mediaCache = _mediaCache.mergeWith(incomingMeta);
            _controller.add(_mediaCache);
          }
        });

    // Request cached metadata
    FlutterBackgroundService().invoke('request_media_state');
  }

  Future<void> _setBackgroundListeners() async {
    await _bgServiceSubscription?.cancel();

    // Listens to control commands
    _bgServiceSubscription = _backgroundService
        ?.on('media_control_command')
        .listen((message) {
          if (message != null) {
            if (message.containsKey('method')) {
              _sendSongChange(message['method']);
            } else if (message.containsKey('position')) {
              _sendSeekChange(message['position']);
            }
          }
        });

    // Sends cached metadata on request
    _backgroundService?.on('request_media_state').listen((_) {
      if (_lastCacheTime == null) {
        _backgroundService?.invoke('media_meta_update', _mediaCache.toMap());
        return;
      }

      if (_mediaCache.isEmpty) return;

      final elapsed = DateTime.now().difference(_lastCacheTime!).inSeconds;

      int? projectedPosition = _mediaCache.position;
      if (_mediaCache.status == true && projectedPosition != null) {
        projectedPosition += elapsed;

        final duration = _mediaCache.duration;
        if (duration != null && duration > 0 && projectedPosition > duration) {
          projectedPosition = duration;
        }
      }

      MediaInfo updatedMetadata = _mediaCache.copyWith(
        isValid: _mediaCache.isValid,
        position: projectedPosition,
      );

      _backgroundService?.invoke('media_meta_update', updatedMetadata.toMap());
    });
  }
}
