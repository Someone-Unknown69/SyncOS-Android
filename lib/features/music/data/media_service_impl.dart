import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/i_media_service.dart';
import '../domain/models/media_info.dart';

// The logic here is essentially a data-processing pipeline. 
// The service opens a persistent channel to the OS (via EventChannel), pipes the raw map data
// through a MediaInfo parser, and performs a diffing operation against the _lastMetadata buffer.

// If the state hasn't meaningfully changed, it drops the packet at the service level.
// The StreamController.broadcast ensures that if you decide to hook in multiple 
// listeners later (e.g., a local mini-player UI and the socket relay), they all receive the 
// same stream of data without needing to re-poll the native side.

class MediaServiceImpl implements IMediaService{
  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  final StreamController<MediaInfo> _controller = StreamController<MediaInfo>.broadcast();
  StreamSubscription? _musicSubscription;
  MediaInfo _lastMetadata = MediaInfo.empty;

  MediaServiceImpl({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('com.example.music_detection'),
        _eventChannel = eventChannel ?? const EventChannel('com.example.music_detection/events');

  @override
  Stream<MediaInfo> get mediaStream => _controller.stream;

  @override
  void init() {
    _methodChannel.invokeMethod('initializeMusicDetection').then((granted) {
      if (granted == true) {
        _startListening();
      }
    });
  }

  void _startListening() {
    _methodChannel.invokeMethod('getCurrentMusicInfo').then((result) {
      if (result != null) _processMap(Map<String, dynamic>.from(result as Map));
    });

    _musicSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) => _processMap(Map<String, dynamic>.from(event as Map)),
      onError: (e) => _controller.addError(e),
    );
  }

  void _processMap(Map<String, dynamic> map) {
    final newInfo = MediaInfo.fromMap(map);
    
    if (newInfo.isValid && _hasChanged(newInfo)) {
      _lastMetadata = newInfo;
      _controller.add(newInfo);
    }
  }

  bool _hasChanged(MediaInfo newInfo) {
    // Basic diffing to prevent unnecessary UI updates
    return newInfo.title != _lastMetadata.title ||
           newInfo.status != _lastMetadata.status ||
           (newInfo.position - _lastMetadata.position).abs() > 1;
  }


  @override
  Future<void> sendControlCommand(String action, Map<String, dynamic> args) async {
    final int position = args['position'];
    try {
      if (action == 'seek') {
        await _methodChannel.invokeMethod('seek', {'position': position * 1000});
      } else {
        await _methodChannel.invokeMethod(action);
      }
    } catch (e) {
      throw Exception("Media Control failed: $e");
    }
  }

  @override
  void dispose() {
    _stopListening();
    _controller.close();
  }

  void _stopListening() {
    _musicSubscription?.cancel();
    _musicSubscription = null;
  }

}