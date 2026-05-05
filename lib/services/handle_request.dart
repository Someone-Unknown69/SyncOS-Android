import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'music.dart';
import '../socket_client.dart';

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

  factory MediaMetadata.initial() {
    return const MediaMetadata(
      title: "Unknown",
      artist: "Unknown",
      album: "Unknown",
      albumArt: "N/A",
      status: "Playing",
      volume: 0.0,
      position: 0,
      duration: 0,
    );
  }
  
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


class HandleRequest {
  static final HandleRequest _instance = HandleRequest._internal();
  factory HandleRequest() => _instance;
  HandleRequest._internal() {
    _handlers = {
      "battery_info": _handleBattery,
      "music": _handleMusic,
      "fetch_art": _handleFetchArt,
    };
  }

  // Map of op to the handler functions
  late final Map<String, Function(Map<String, dynamic>)> _handlers;
  MediaPoller? _mediaPoller;

  /// Device Information
  final ValueNotifier<int> batteryLevel = ValueNotifier<int>(0);
  final ValueNotifier<String> deviceName = ValueNotifier<String>("Unknown");
  final ValueNotifier<bool> isCharging = ValueNotifier<bool>(false);
  
  final ValueNotifier<MediaMetadata> metadata = ValueNotifier(MediaMetadata.initial());
  
  String _httpUrl = '';
  String get httpUrl => _httpUrl;

  void setHttpUrl(String url) {
    _httpUrl = url;
  }

  // Optimistic update for UI responsiveness
  void updateStatus(String newStatus) {
    metadata.value = metadata.value.copyWith(status: newStatus);
  }

  void handle(String rawJson) {
    try {
      debugPrint('Command recieved $rawJson');
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

  void _handleBattery(Map<String, dynamic> data) {
    final args = data['args'];
    batteryLevel.value = args['level'] ?? 0;
    isCharging.value = args['status'] ?? false;
    deviceName.value = args['device'] ?? "Unknown";
  }

  void _handleFetchArt(Map<String, dynamic> data) {
    if (_httpUrl.isNotEmpty) {
      _fetchAlbumArt(); // Fetch immediately
    }
  }

  void _handleMusic(Map<String, dynamic> data) {
    final action = data['action'];
    final args = data['args'];

    if(action == 'update_metadata') {
      debugPrint("Updated metadata recieved : $args");

      final newTitle = args['title'] ?? 'Unknown';
      final oldTitle = metadata.value.title;

      // Dirty cache
      if (newTitle == 'Unknown' && oldTitle != 'Unknown') {
        metadata.value = metadata.value.copyWith(
          status: args['status'],
          volume: args['volume'],
          duration: args['duration'],
          position: args['position'],
          albumArt: args['albumArt'] ?? metadata.value.albumArt,
        );
        return;
      }
      
      metadata.value = metadata.value.copyWith(
        title: newTitle,
        artist: args['artist'],
        album: args['album'],
        status: args['status'],
        volume: args['volume'],
        duration: args['duration'],
        position: args['position'],
        albumArt: args['albumArt'] ?? metadata.value.albumArt,
      );
      
      // Proactively fetch album art when the song changes
      if (newTitle != oldTitle && newTitle != 'Unknown' && _httpUrl.isNotEmpty) {
        _fetchAlbumArt(); // Fetch immediately
      }
    } else if (action == 'control') {
      _mediaPoller ??= SocketClient.instance.music;

      if (_mediaPoller != null) {
        _mediaPoller!.control(args);
      } else {
        debugPrint('Error: MediaPoller not set in HandleRequest');
      }
    }
  }
  
  Future<void> _fetchAlbumArt({int retryCount = 0}) async {
    try {
      final response = await http.get(Uri.parse('$_httpUrl/art')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['albumArt'] != null && data['albumArt'].toString().isNotEmpty) {
          metadata.value = metadata.value.copyWith(albumArt: data['albumArt']);
          return; // Success!
        }
      }

      // Retry up to 3 times with a short 200ms delay if art isn't ready
      if (retryCount < 3) {
        await Future.delayed(const Duration(milliseconds: 200));
        return _fetchAlbumArt(retryCount: retryCount + 1);
      }
    } catch (e) {
      if (retryCount < 3) {
        await Future.delayed(const Duration(milliseconds: 200));
        return _fetchAlbumArt(retryCount: retryCount + 1);
      }
      debugPrint("Failed to fetch album art: $e");
    }

    // Final fallback
    if (retryCount >= 3) {
      metadata.value = metadata.value.copyWith(albumArt: "N/A");
    }
  }
}
