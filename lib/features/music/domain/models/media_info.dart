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
    return MediaInfo(
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown',
      status: map['isPlaying'] == true,
      position: ((map['currentPosition'] as int?) ?? 0) ~/ 1000,
      duration: ((map['duration'] as int?) ?? 0) ~/ 1000,
      albumArtBase64: map['albumArtBase64'] as String? ?? 'N/A',
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
