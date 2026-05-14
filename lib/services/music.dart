import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
  Map<String, dynamic> current = {};
  Map<String, dynamic> lastSent = {};
  int lastSentTime = 0;
  bool isFirstEvent = true;

  bool hasChanged() => isFirstEvent || current != lastSent;

  void updateLastSent(Map<String, dynamic> info) {
    lastSent = Map.from(info);
    lastSentTime = DateTime.now().millisecondsSinceEpoch;
    isFirstEvent = false;
  }
}


class MediaPoller {
  static const MethodChannel _methodChannel = MethodChannel('com.example.music_detection');
  static const EventChannel _eventChannel = EventChannel('com.example.music_detection/events');

  /// I will add option to manuall add a player in this
  static const Set<String> _musicApps = {
    'com.spotify.music',
    'com.apple.android.music',
    'com.google.android.apps.youtube.music',
    'com.amazon.mp3',
    'com.pandora.android',
    'com.deezer.android.app',
    'com.tidal.android',
    'com.claro.music',
    'com.soundcloud.android',
    'com.lastfm',
    'com.metrolist.music',
    'com.maxmpz.audioplayer',
    'com.sec.android.app.music',
    'com.android.music',
    'com.doubbleclick.sexymp3',
    'com.music.player',
    'com.poweramp.infinitum',
    'com.jrtstudio.musicplayer',
    'cn.kuwo.aweme',
    'com.netease.cloudmusic',
    'com.tencent.qqmusic',
    'com.kugou.android',
    'com.kmplayer',
    'com.mx.music',
  };

  final _MusicInfoCache _cache = _MusicInfoCache();
  StreamSubscription? _musicSubscription;
  void Function(MediaInfo)? onMediaUpdate;
  String _lastSentTitle = "";
  String _lastSentArtist = "";

  bool _isMusicApp(String? packageName) {
    if (packageName == null) return false;
    if (_musicApps.contains(packageName)) return true;
    if (packageName.toLowerCase().contains('music')) return true;
    if (packageName.toLowerCase().contains('spotify')) return true;
    return false;
  }

  bool _hasChanged(Map<String, dynamic> info) {
    if (_cache.lastSent.isEmpty) return true;
    
    final lastIsPlaying = _cache.lastSent['isPlaying'] == true;
    final lastPosition = (_cache.lastSent['currentPosition'] as int?) ?? 0;
    
    final nowPlaying = info['isPlaying'] == true;
    final nowPosition = (info['currentPosition'] as int?) ?? 0;
    final nowTime = DateTime.now().millisecondsSinceEpoch;
    
    // Calculate where the track should be right now if it was playing normally
    final expectedPosition = lastIsPlaying 
        ? lastPosition + (nowTime - _cache.lastSentTime)
        : lastPosition;
        
    // If the difference is greater than 1 second (1000ms), it's a manual seek/jump
    final seeked = (nowPosition - expectedPosition).abs() > 1000;
    final playStateChanged = lastIsPlaying != nowPlaying;

    return _cache.lastSent['title'] != info['title'] ||
        _cache.lastSent['artist'] != info['artist'] ||
        _cache.lastSent['packageName'] != info['packageName'] ||
        _cache.lastSent['album'] != info['album'] ||
        _cache.lastSent['duration'] != info['duration'] ||
        seeked ||
        playStateChanged;
  }

  // for permissions
  void init({void Function(MediaInfo)? onUpdate, required void Function(String op, String action, Map<String, dynamic> args) onSend}) async {
    onMediaUpdate = onUpdate;
    debugPrint("starting subscription");

    try {
      final result = await _methodChannel.invokeMethod('initializeMusicDetection');
      final initData = Map<dynamic, dynamic>.from(result);
      final bool permissionGranted = initData['permissionGranted'] == true;

      if (!permissionGranted) {
        debugPrint("Notification listener access not enabled");
        await _methodChannel.invokeMethod('openNotificationSettings');
      } else {
        debugPrint("Notification listener access is enabled");
      }

      _startSubscription(onSend);
    } catch (e) {
      debugPrint('we cooked : $e');
    }
  }

  // starting the music subscription
  void _startSubscription(void Function(String op, String action, Map<String, dynamic> args) onSend) {
    _musicSubscription?.cancel();

    // Poll current state once immediately on startup
    _methodChannel.invokeMethod('getCurrentMusicInfo').then((result) {
      if (result != null) {
        final info = Map<String, dynamic>.from(result as Map);
        _updateMetadata(info, onSend);
      }
    }).catchError((e) { debugPrint('getCurrentMusicInfo error: $e'); });

    _musicSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final Map<dynamic, dynamic>? raw = event as Map<dynamic, dynamic>?;
          if (raw == null) return;
          _updateMetadata(Map<String, dynamic>.from(raw), onSend);
        } catch (e) {
          debugPrint("error in subscription handler: $e");
        }
      },
      onError: (error) => debugPrint('Event channel error: $error'),
      onDone: () => debugPrint('Event channel stream closed'),
    );
  }

  // this updates and changes metadata
  void _updateMetadata(Map<String, dynamic> info, void Function(String op, String action, Map<String, dynamic> args) onSend) {
    final packageName = info['packageName'] as String?;
    if (!_isMusicApp(packageName)) return;
    
    final title = info['title'] ?? 'Unknown';
    final artist = info['artist'] ?? 'Unknown Artist';
    final duration = ((info['duration'] as int?) ?? 0) ~/ 1000;
    
    // Ignore updates with missing data or 0 duration
    if (title == 'Unknown' || title.isEmpty || duration == 0) return;

    if (!_hasChanged(info)) return;

    _cache.current = info;
    _cache.updateLastSent(info);

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
      debugPrint('Now playing: ${metadata.title} — ${metadata.artist}');
      debugPrint('More info: ${metadata.album} — ${metadata.position} / ${metadata.duration}');
    } else {
      debugPrint('Playback paused or stopped');
    }

    // send updated metadata to server
    final map = metadata.toMap();
    
    // Only include the heavy album art in the socket message if the song has actually changed
    // AND we haven't successfully sent art for this song yet.
    if (metadata.title != _lastSentTitle || metadata.artist != _lastSentArtist) {
      if (metadata.albumArtBase64 != 'N/A') {
        map['albumArt'] = metadata.albumArtBase64;
        _lastSentTitle = metadata.title;
        _lastSentArtist = metadata.artist;
      }
    }

    onSend('music', 'update_metadata', map);

    onMediaUpdate?.call(metadata);
  }

  void control(Map<String, dynamic> args) {
    _control(args);
  }


  Future<void> _control(Map<String, dynamic> args) async {
    try {
      String method = '';
      if (args['method'] == 'next') {
        method = 'next';
      } else if (args['method'] == 'previous') {
        method = 'previous';
      } else if (args['method'] == 'play_pause') {
        method = 'playPause';
      } else if (args['method'] == 'seek') {
        await seek(args['position']);
        return;
      }

      await _methodChannel.invokeMethod(method);
      debugPrint("Sent $method command");
    } catch (e) {
      debugPrint("Failed to send ${args['method']}: $e");
    }
  }

  Future<void> seek(int positionSeconds) async {
    try {
      final positionMs = positionSeconds * 1000;
      await _methodChannel.invokeMethod('seek', {'position': positionMs});
      debugPrint("Seeked to $positionSeconds seconds");
    } catch (e) {
      debugPrint("Failed to seek: $e");
    }
  }


  void stopMusicSubscription() {
    debugPrint('Music subscription stopping');
    _musicSubscription?.cancel();
    _musicSubscription = null;
  }
}
