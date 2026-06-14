// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/foundation.dart';

@immutable
class MediaInfo {
  final String title;
  final String artist;
  final String album;
  final bool status;
  final int position;
  final int duration;
  final String albumArtBase64;

  const MediaInfo({
    required this.title, 
    required this.artist, 
    required this.album,
    required this.status, 
    required this.position,
    required this.duration, 
    required this.albumArtBase64,
  });

  factory MediaInfo.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return MediaInfo(
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown',
      status: map['status'] == 'Playing' || map['status'] == true || map['isPlaying'] == true,
      position: toInt(map['position'] ?? map['currentPosition']),
      duration: toInt(map['duration']),
      albumArtBase64: map['albumArt'] ?? map['albumArtBase64'] ?? 'N/A',
    );
  }

  MediaInfo copyWith({
    String? title,
    String? artist,
    String? album,
    bool? status,
    int? position,
    int? duration,
    String? albumArtBase64,
  }) {
    return MediaInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      albumArtBase64: albumArtBase64 ?? this.albumArtBase64,
    );
  }

  static const empty = MediaInfo(
    title: '',
    artist: '',
    album: '',
    status: false,
    position: 0,
    duration: 0,
    albumArtBase64: '',
  );

  bool get isValid => title != 'Unknown' && title.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'title': title, 
    'artist': artist, 
    'album': album,
    'status': status ? 'Playing' : 'Paused', 
    'position': position,
    'duration': duration, 
  };
}
