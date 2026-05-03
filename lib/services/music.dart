import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class MusicTester {
  StreamSubscription? _subscription;

  void startListening() async {
    // In 3.0.3, check if the service is already running
    await NowPlaying.instance.start(resolveImages: false);

    final bool isEnabled = await NowPlaying.instance.isEnabled();
    if (!isEnabled) {
      debugPrint("PERMISSIONS REQUIRED: Opening settings...");
      await NowPlaying.instance.requestPermissions();
      return;
    }

    // Use the stream to listen for changes
    // The type in 3.0.3 is often inferred, but we can be explicit:
    _subscription = NowPlaying.instance.stream.listen((track) {
      _debugLog(track);
    });
    
    // Also get the current track immediately
    final current = await NowPlaying.instance.track;
    _debugLog(current);

    debugPrint("Listener active. Change music on your phone now!");
  }

  void _debugLog(NowPlayingTrack track) {
    debugPrint('--- [v3.0.3] TRACK DETECTED ---');
    debugPrint('Title:  ${track.title}');
    debugPrint('Artist: ${track.artist}');
    debugPrint('App:    ${track.source}'); // e.g. "com.spotify.music"
    debugPrint('State:  ${track.state}');  // playing, paused, etc.
    debugPrint('-------------------------------');
  }

  void stop() {
    _subscription?.cancel();
    NowPlaying.instance.stop();
  }
}