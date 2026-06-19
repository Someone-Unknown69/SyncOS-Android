/// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

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

  final Set<String> _definedFields;

  const MediaInfo({
    required this.title,
    required this.artist,
    required this.album,
    required this.status,
    required this.position,
    required this.duration,
    required this.albumArtBase64,
    Set<String>? definedFields,
  }) : _definedFields =
           definedFields ??
           const {
             'title',
             'artist',
             'album',
             'status',
             'position',
             'duration',
             'albumArtBase64',
           };

  factory MediaInfo.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final trackedFields = <String>{};
    if (map.containsKey('title') && map['title'] != null)
      trackedFields.add('title');
    if (map.containsKey('artist') && map['artist'] != null)
      trackedFields.add('artist');
    if (map.containsKey('album') && map['album'] != null)
      trackedFields.add('album');
    if (map.containsKey('status') || map.containsKey('isPlaying'))
      trackedFields.add('status');
    if (map.containsKey('position') || map.containsKey('currentPosition'))
      trackedFields.add('position');
    if (map.containsKey('duration')) trackedFields.add('duration');
    if (map.containsKey('albumArt') || map.containsKey('albumArtBase64'))
      trackedFields.add('albumArtBase64');

    return MediaInfo(
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown',
      status:
          map['status'] == 'Playing' ||
          map['status'] == true ||
          map['isPlaying'] == true,
      position: toInt(map['position'] ?? map['currentPosition']),
      duration: toInt(map['duration']),
      albumArtBase64: map['albumArt'] ?? map['albumArtBase64'] ?? '',
      definedFields: trackedFields,
    );
  }

  MediaInfo mergeWith(MediaInfo other) {
    if (other == MediaInfo.empty || other._definedFields.isEmpty) {
      return this;
    }

    return MediaInfo(
      title:
          (other._definedFields.contains('title') &&
              other.title.isNotEmpty &&
              other.title != 'Unknown')
          ? other.title
          : title,

      artist:
          (other._definedFields.contains('artist') &&
              other.artist.isNotEmpty &&
              other.artist != 'Unknown Artist')
          ? other.artist
          : artist,

      album:
          (other._definedFields.contains('album') &&
              other.album.isNotEmpty &&
              other.album != 'Unknown')
          ? other.album
          : album,

      status: other._definedFields.contains('status') ? other.status : status,

      position: other._definedFields.contains('position')
          ? other.position
          : position,

      duration:
          (other._definedFields.contains('duration') && other.duration > 0)
          ? other.duration
          : duration,

      albumArtBase64:
          (other._definedFields.contains('albumArtBase64') &&
              other.albumArtBase64.isNotEmpty)
          ? other.albumArtBase64
          : albumArtBase64,

      definedFields: _definedFields.union(other._definedFields),
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
    final trackedFields = Set<String>.from(_definedFields);
    if (title != null) trackedFields.add('title');
    if (artist != null) trackedFields.add('artist');
    if (album != null) trackedFields.add('album');
    if (status != null) trackedFields.add('status');
    if (position != null) trackedFields.add('position');
    if (duration != null) trackedFields.add('duration');
    if (albumArtBase64 != null) trackedFields.add('albumArtBase64');

    return MediaInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      albumArtBase64: albumArtBase64 ?? this.albumArtBase64,
      definedFields: trackedFields,
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
    definedFields: {},
  );

  bool get isValid => title != 'Unknown' && title.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'title': title,
    'artist': artist,
    'album': album,
    'status': status ? 'Playing' : 'Paused',
    'position': position,
    'duration': duration,
    'albumArt': albumArtBase64,
  };

  static MediaInfo getDifference(MediaInfo oldInfo, MediaInfo newInfo) {
    final diffFields = <String>{};

    void check(String field, dynamic oldValue, dynamic newValue) {
      if (oldValue != newValue) {
        diffFields.add(field);
      }
    }

    check('title', oldInfo.title, newInfo.title);
    check('artist', oldInfo.artist, newInfo.artist);
    check('album', oldInfo.album, newInfo.album);
    // always keep status and position as new Info status
    check('duration', oldInfo.duration, newInfo.duration);
    check('albumArtBase64', oldInfo.albumArtBase64, newInfo.albumArtBase64);

    return MediaInfo(
      title: diffFields.contains('title') ? newInfo.title : '',
      artist: diffFields.contains('artist') ? newInfo.artist : '',
      album: diffFields.contains('album') ? newInfo.album : '',
      status: newInfo.status,
      position: newInfo.position,
      duration: diffFields.contains('duration') ? newInfo.duration : 0,
      albumArtBase64: diffFields.contains('albumArtBase64')
          ? newInfo.albumArtBase64
          : '',
      definedFields: diffFields,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaInfo &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist &&
          album == other.album &&
          status == other.status &&
          position == other.position &&
          duration == other.duration &&
          albumArtBase64 == other.albumArtBase64;

  @override
  int get hashCode =>
      title.hashCode ^
      artist.hashCode ^
      album.hashCode ^
      status.hashCode ^
      position.hashCode ^
      duration.hashCode ^
      albumArtBase64.hashCode;
}
