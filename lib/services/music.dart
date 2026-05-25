import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mobile_controller/services/socket_client.dart';

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


class _MusicInfoCache {
  Map<String, dynamic> lastSent = {};
  int lastSentTime = 0;
  String lastTrackIdentity = "";

  void update(Map<String, dynamic> info, String trackIdentity) {
    lastSent = info;
    lastTrackIdentity = trackIdentity;
    lastSentTime = DateTime.now().millisecondsSinceEpoch;
  }
}


class MediaPoller {
  static const MethodChannel _methodChannel = MethodChannel('com.example.music_detection');
  static const EventChannel _eventChannel = EventChannel('com.example.music_detection/events');

  final _MusicInfoCache _cache = _MusicInfoCache();
  StreamSubscription? _musicSubscription;
  void Function(MediaInfo)? onMediaUpdate;

  bool _hasChanged(Map<String, dynamic> info) {
    // lots of checks on each step is applied to optimize the comparision system

    if (_cache.lastSent.isEmpty) return true;
    final last = _cache.lastSent;

    // If the track properties don't match, return immediately
    if (last['title'] != info['title'] ||
        last['artist'] != info['artist'] ||
        last['packageName'] != info['packageName'] ||
        last['album'] != info['album'] ||
        last['duration'] != info['duration']) {
      return true;
    }
    
    final lastIsPlaying = _cache.lastSent['isPlaying'] == true;
    final nowPlaying = info['isPlaying'] == true;

    if (lastIsPlaying != nowPlaying) return true;

    final lastPosition = (_cache.lastSent['currentPosition'] as int?) ?? 0;
    final nowPosition = (info['currentPosition'] as int?) ?? 0;

    if (lastPosition == nowPosition) return false;

    final nowTime = DateTime.now().millisecondsSinceEpoch;
    // Calculate where the track should be right now if it was playing normally
    final expectedPosition = lastIsPlaying 
        ? lastPosition + (nowTime - _cache.lastSentTime)
        : lastPosition;

    // If the difference is greater than 1 second (1000ms), it's a manual seek/jump
    return (nowPosition - expectedPosition).abs() > 1000;
  }

  // for permissions
  void init({void Function(MediaInfo)? onUpdate}) async {
    onMediaUpdate = onUpdate;
    debugPrint("[Music Handling] starting subscription");

    try {
      final result = await _methodChannel.invokeMethod('initializeMusicDetection');
      final bool permissionGranted = result == true;

      if (!permissionGranted) {
        debugPrint("[Music Handling] Notification listener access not enabled");
        await _methodChannel.invokeMethod('openNotificationSettings');
      } else {
        debugPrint("[Music Handling] Notification listener access is enabled");
      }

      _startSubscription();
    } catch (e) {
      debugPrint('[Music Handling] Error while initializing : $e');
    }
  }

  // starting the music subscription
  void _startSubscription() {
    _musicSubscription?.cancel();

    // Poll current state once immediately on startup
    _methodChannel.invokeMethod('getCurrentMusicInfo').then((result) {
      if (result != null) {
        final info = Map<String, dynamic>.from(result as Map);
        _updateMetadata(info);
      }
    }).catchError((e) { debugPrint('[Music Handling] getCurrentMusicInfo error: $e'); });

    _musicSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final Map<dynamic, dynamic>? raw = event as Map<dynamic, dynamic>?;
          if (raw == null) return;
          _updateMetadata(Map<String, dynamic>.from(raw));
        } catch (e) {
          debugPrint("[Music Handling] error in subscription handler: $e");
        }
      },
      onError: (error) => debugPrint('[Music Handling] Event channel error: $error'),
      onDone: () => debugPrint('[Music Handling] Event channel stream closed'),
    );
  }

  // this updates and changes metadata
  void _updateMetadata(Map<String, dynamic> info) {
    final title = info['title'] ?? 'Unknown';
    final artist = info['artist'] ?? 'Unknown Artist';
    final duration = ((info['duration'] as int?) ?? 0) ~/ 1000;
    
    // Ignore updates with missing data or 0 duration
    if (title == 'Unknown' || title.isEmpty || duration == 0) return;

    if (!_hasChanged(info)) return;

    final currentIdentity = "$title-$artist";
    final isNewSong = currentIdentity != _cache.lastTrackIdentity;

    _cache.update(info, currentIdentity);

    final metadata = MediaInfo(
      status: info['isPlaying'] == true,
      title: title,
      album: info['album'] ?? 'Unknown',
      artist: artist,
      duration: duration,
      position: ((info['currentPosition'] as int?) ?? 0) ~/ 1000,
      albumArtBase64: info['albumArtBase64'] as String? ?? 'N/A',
    );

    if (metadata.status) {
      debugPrint('[Music Handling] Now playing: ${metadata.title} — ${metadata.artist}');
    } else {
      debugPrint('[Music Handling] Playback paused or stopped');
    }

    // send updated metadata to server
    final map = metadata.toMap();
    
    // Only include the heavy album art in the socket message if the song has actually changed
    // AND we haven't successfully sent art for this song yet.
    if (isNewSong && metadata.albumArtBase64 != 'N/A') {
      map['albumArt'] = metadata.albumArtBase64;
    }

    SocketClient.instance.send('music', 'update_metadata', map);

    onMediaUpdate?.call(metadata);
  }

  void control(Map<String, dynamic> args) {
    _control(args);
  }


  Future<void> _control(Map<String, dynamic> args) async {
    try {
      final methodPattern = args['method'];
      if (methodPattern == 'seek') {
        await seek(args['position']);
        return;
      }

      final methodMap = {
        'next': 'next',
        'previous': 'previous',
        'play_pause': 'playPause'
      };

      final targetMethod = methodMap[methodPattern];
      if (targetMethod != null) {
        await _methodChannel.invokeMethod(targetMethod);
        debugPrint("[Music Handling] Sent $targetMethod command");
      }
    } catch (e) {
      debugPrint("[Music Handling] Failed to execute control command: $e");
    }
  }

  Future<void> seek(int positionSeconds) async {
    try {
      final positionMs = positionSeconds * 1000;
      await _methodChannel.invokeMethod('seek', {'position': positionMs});
      debugPrint("[Music Handling] Seeked to $positionSeconds seconds");
    } catch (e) {
      debugPrint("[Music Handling] Failed to seek: $e");
    }
  }


  void stopMusicSubscription() {
    debugPrint('[Music Handling] Music subscription stopping');
    _methodChannel.invokeMethod('dispose');
    _musicSubscription?.cancel();
    _musicSubscription = null;
  }
}
