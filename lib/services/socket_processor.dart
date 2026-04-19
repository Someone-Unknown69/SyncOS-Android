import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Metadata class
class MediaMetadata {
  final String title;
  final String artist;
  final String album;
  final String albumArt;
  final String status;
  final int position;
  final int duration;
  final double volume;

  const MediaMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArt,
    required this.status,
    required this.position,
    required this.duration,
    required this.volume,
    
  });

  // A factory to provide default "empty" values
  factory MediaMetadata.initial() {
    return const MediaMetadata(
      title: "Unknown",
      artist: "Unknown",
      album: "Unknown",
      albumArt: "N/A",
      status: "Playing",
      volume: 0.0,
      position: 50,
      duration: 100,
    );
  }
  
  // Useful for updating specific fields without recreating everything
  MediaMetadata copyWith({
    String? title, 
    String? artist, 
    String? album, 
    String? albumArt, 
    String? status,
    double? volume,
    int? position,
    int? duration,
    }) {
    return MediaMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArt: albumArt ?? this.albumArt,
      status: status ?? this.status,
      volume: volume ?? this.volume,
      duration: duration ?? this.duration,
      position: position ?? this.position
    );
  }
}


class SocketProcessor {
  static final SocketProcessor _instance = SocketProcessor._internal();
  factory SocketProcessor() => _instance;
  SocketProcessor._internal() {
    _handlers = {
      "sys_info": _handleStatus,
      "music": _handleMusic,
    };
  }

  // Map of op to the handler functions
  late final Map<String, Function(Map<String, dynamic>)> _handlers;

  /// Device Information
  final ValueNotifier<int> batteryLevel = ValueNotifier<int>(0);
  final ValueNotifier<String> deviceName = ValueNotifier<String>("Unknown");
  final ValueNotifier<bool> isCharging = ValueNotifier<bool>(false);
  final ValueNotifier<int> latency = ValueNotifier<int>(0);
  final Stopwatch stopwatch = Stopwatch();

  final ValueNotifier<MediaMetadata> metadata = ValueNotifier(MediaMetadata.initial());


  void handle(String rawJson) {
    try {
      final data = jsonDecode(rawJson);
      final op = data['op'];

      if (_handlers.containsKey(op)) {
        _handlers[op]!(data);
      } else {
        debugPrint("Unknown operation: $op");
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  // ---------------------------     Individual Handler Logics      ---------------------------------

  void _handleStatus(Map<String, dynamic> data) {
    final args = data['args'];
    debugPrint("$args");
    deviceName.value = args['name'] ?? "Unknown";
    batteryLevel.value = args['battery'] ?? 0;
    isCharging.value = args['isCharging'] ?? false;
    
    latency.value = stopwatch.elapsedMilliseconds;
    stopwatch.reset();
    stopwatch.start();

    // debugPrint("Updated: ${deviceName.value} - ${isCharging.value}%");

  }

  void _handleMusic(Map<String, dynamic> songInfo) {
    final args = songInfo['args'];
    
    metadata.value = metadata.value.copyWith(
      title: args['title'],
      artist: args['artist'],
      album: args['album'],
      albumArt: args['albumArt'],
      status: args['status'],
      volume: args['volume'],
      duration: args['duration'],
      position: args['position'],
    );
  }

}
