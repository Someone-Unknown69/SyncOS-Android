// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:syncos_android/core/media/domain/i_local_media_info.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/features/media/domain/models/media_info.dart';

// The logic here is essentially a data-processing pipeline.
// The service opens a channel to the EventChannel, pipes the raw map data

class AndroidMediaInfo implements ILocalMediaInfo {
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  final StreamController<MediaInfo> _metadataController =
      StreamController<MediaInfo>.broadcast();

  StreamSubscription? _streamSubscription;

  @override
  Stream<MediaInfo> get metadataStream => _metadataController.stream;

  AndroidMediaInfo({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel('com.example.music_detection'),
      _eventChannel =
          eventChannel ??
          const EventChannel('com.example.music_detection/events');

  @override
  Future<void> start() async {
    try {
      final granted = await _methodChannel.invokeMethod(
        'initializeMusicDetection',
      );
      logDebug(
        'Android Media Info',
        'initializeMusicDetection granted=$granted',
      );
      _startListening();
    } catch (e) {
      logDebug(
        'Android Media Info',
        'Failed to initialize platform channels: $e',
      );
    }
  }

  void _startListening() {
    _stopListening();

    _methodChannel.invokeMethod('getCurrentMusicInfo').then((result) {
      if (result != null) {
        final Map<String, dynamic> typedResult = Map<String, dynamic>.from(
          result as Map,
        );
        _metadataController.add(MediaInfo.fromMap(typedResult));
      }
    });

    _streamSubscription = _eventChannel.receiveBroadcastStream().listen((
      dynamic result,
    ) {
      if (result == null || result is! Map) return;

      final Map<String, dynamic> typedResult = Map<String, dynamic>.from(
        result,
      );

      if (typedResult.isEmpty ||
          typedResult['packageName'] == 'com.syncos.syncos_android') {
        return;
      }
      _metadataController.add(MediaInfo.fromMap(typedResult));
    });
  }

  @override
  void stop() {
    _stopListening();
  }

  @override
  void dispose() {
    stop();
    if (!_metadataController.isClosed) {
      _metadataController.close();
    }
  }

  void _stopListening() {
    if (_streamSubscription != null) {
      _streamSubscription!.cancel();
      _streamSubscription = null;
      logDebug(
        'Android Media Info',
        "Music platform channels cleanly detached",
      );
    }
  }

  @override
  void control(Map<String, dynamic> args) {
    _control(args);
  }

  void _control(Map<String, dynamic> args) async {
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

      logDebug(
        'Android Media Info',
        "Called method ${methodPattern.toString()}",
      );

      final targetMethod = methodMap[methodPattern];
      if (targetMethod != null) {
        await _methodChannel.invokeMethod(targetMethod);
      }
    } catch (e) {
      throw Exception("Android Media Control failed: $e");
    }
  }
}
