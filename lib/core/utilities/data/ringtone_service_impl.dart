// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/utilities/domain/i_ringtone_service.dart';

class AndroidRingtoneService implements IRingtoneService {
  bool _isRinging = false;
  Timer? _ringTimeoutTimer;

  @override
  Future<void> ringDevice({
    required Map<String, dynamic> data,
  }) async {
    if(!_isRinging) {
      final isLooping = data['is_looping'] == true || data['is_looping'] == 'true';
      final isAlarm = data['is_alarm'] == true || data['is_alarm'] == 'true';
      final durationSeconds = int.tryParse(data['duration_seconds']?.toString() ?? '') ?? 15;
      
      // TODO : ADD a notification to cancel the ring
      FlutterRingtonePlayer().playRingtone(
        volume: 1.0,
        looping: isLooping,
        asAlarm: isAlarm,
      );
      _isRinging = true;

      _ringTimeoutTimer = Timer(Duration(seconds: durationSeconds), () {
        logDebug('Ringtone Service', 'Auto-stopping ringtone after timeout context');
        stopRing();
      });
    } else {
      logDebug('Ringtone Service', 'Already playing');
    }
  }

  @override
  Future<void> stopRing() async {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
    
    if(!_isRinging) return;
    FlutterRingtonePlayer().stop();
    _isRinging = false;
  }

  @override
  bool get isRinging => _isRinging;
}