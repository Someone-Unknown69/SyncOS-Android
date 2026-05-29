import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import '../domain/i_local_media_sender.dart';
import '../domain/models/media_info.dart';
import 'package:flutter/foundation.dart';

// The logic here is essentially a data-processing pipeline. 
// The service opens a persistent channel to the OS (via EventChannel), pipes the raw map data
// through a MediaInfo parser, and performs a diffing operation against the _lastMetadata buffer.

// If the state hasn't meaningfully changed, it drops the packet at the service level.
// The StreamController.broadcast ensures that if we decide to hook in multiple 
// listeners later (e.g., a local mini-player UI and the socket relay), they all receive the 
// same stream of data without needing to re-poll the native side.

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

class MediaServiceImpl implements IMediaService{
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final IConnectionManager _connectionManager;

  final StreamController<MediaInfo> _controller = StreamController<MediaInfo>.broadcast();
  StreamSubscription? _musicSubscription;
  final _MusicInfoCache _cache = _MusicInfoCache();

  MediaServiceImpl({
    required IConnectionManager connectionManager, 
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _connectionManager = connectionManager,
        _methodChannel = methodChannel ?? const MethodChannel('com.example.music_detection'),
        _eventChannel = eventChannel ?? const EventChannel('com.example.music_detection/events');

  @override
  Stream<MediaInfo> get mediaStream => _controller.stream;

  @override
  Future<void> start() async {
    final granted = await _methodChannel.invokeMethod('initializeMusicDetection');
    if (granted == true) {
      _startListening();
    }
  }

  void _startListening() {
    _stopListening(); 
    _methodChannel.invokeMethod('getCurrentMusicInfo').then((result) {
      if (result != null) _processMap(Map<String, dynamic>.from(result as Map));
    });

    _musicSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) => _processMap(Map<String, dynamic>.from(event as Map)),
      onError: (e) => _controller.addError(e),
    );
  }

void _processMap(Map<String, dynamic> info) {
  // Initial/Ghost Guard
  final int duration = (info['duration'] as int? ?? 0) ~/ 1000;
  if (duration <= 0) return;

  final bool isNewTrack = _isNewTrack(info);
  final bool isStateChange = (_cache.lastSent['isPlaying'] == true) != (info['isPlaying'] == true);
  final bool isSeek = _isSignificantSeek(info);

  // If last art was null / NA and new art is available
  final String? lastArt = _cache.lastSent['albumArtBase64'] as String?;
  final String? newArt = info['albumArtBase64'] as String?;
  final bool isArtDelayed = (lastArt == null || lastArt == 'N/A') && (newArt != null && newArt != 'N/A');

  // If it's a new track, send Song Change. 
  // If not, but state changed, send State Change.
  // If neither, but seeked, send State Change.
  
  if (isNewTrack || isArtDelayed) {
    debugPrint('[Media Service] Song Change');
    _sendSongChange(info);
  } else if (isStateChange || isSeek) {
    debugPrint('[Media Service] State/Seek Change');
    _sendStateChange(info);
    _cache.update(info, _cache.lastTrackIdentity); // Update cache without triggering song-change logic
  }
}

  bool _isNewTrack(Map<String, dynamic> info) {
    final last = _cache.lastSent;
    return last['title'] != info['title'] ||
          last['artist'] != info['artist'] ||
          last['album'] != info['album'];
  }

  bool _isSignificantSeek(Map<String, dynamic> info) {
    if (_cache.lastSent.isEmpty) return false;
    final lastPosition = (_cache.lastSent['currentPosition'] as int?) ?? 0;
    final nowPosition = (info['currentPosition'] as int?) ?? 0;
    
    final nowTime = DateTime.now().millisecondsSinceEpoch;
    final expectedPosition = (_cache.lastSent['isPlaying'] == true) 
        ? lastPosition + (nowTime - _cache.lastSentTime)
        : lastPosition;

    return (nowPosition - expectedPosition).abs() > 5000;
  }


  void _sendSongChange(Map<String, dynamic> info) {
    final metadata = MediaInfo(
      status: info['isPlaying'] == true,
      title: info['title'] ?? 'Unknown',
      album: info['album'] ?? 'Unknown',
      artist: info['artist'] ?? 'Unknown Artist',
      duration: ((info['duration'] as int?) ?? 0) ~/ 1000,
      position: ((info['currentPosition'] as int?) ?? 0) ~/ 1000,
      albumArtBase64: info['albumArtBase64'] as String? ?? 'N/A',
    );

    final payload = metadata.toMap();
    payload['albumArt'] = metadata.albumArtBase64;

    _connectionManager.send('music', 'update_metadata', payload);

    final currentIdentity = "${metadata.title}-${metadata.artist}";
    _cache.update(info, currentIdentity);

    return;
  }

  void _sendStateChange(Map<String, dynamic> info) {
    final metadata = MediaInfo(
      status: info['isPlaying'] == true,
      title: info['title'] ?? 'Unknown',
      album: info['album'] ?? 'Unknown',
      artist: info['artist'] ?? 'Unknown Artist',
      duration: ((info['duration'] as int?) ?? 0) ~/ 1000,
      position: ((info['currentPosition'] as int?) ?? 0) ~/ 1000,
      albumArtBase64: info['albumArtBase64'] as String? ?? 'N/A',
    );

    final payload = metadata.toMap();
  
    _connectionManager.send('music', 'update_metadata', payload);

    return;
  }

  @override
  Future<void> sendControlCommand(Map<String, dynamic> args) async {
    try {
      final position = args['position'];
      final methodPattern = args['method'];
      
      if (methodPattern == 'seek') {
        await _methodChannel.invokeMethod('seek', {'position': position * 1000});
      }

      final methodMap = {
        'next': 'next',
        'previous': 'previous',
        'play_pause': 'playPause'
      };

      final targetMethod = methodMap[methodPattern];
      if (targetMethod != null) {
        await _methodChannel.invokeMethod(targetMethod);
      }
    } catch (e) {
      throw Exception("Media Control failed: $e");
    }
  }

  @override
  void stop() {
    _stopListening();
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }

  void _stopListening() {
    _musicSubscription?.cancel();
    _musicSubscription = null;
  }

}