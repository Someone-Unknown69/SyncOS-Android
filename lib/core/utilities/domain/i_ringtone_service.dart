// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

// THIS SHALL RUN IN BACKGROUND ONLY BTW

abstract class IRingtoneService {
  /// Starts playing the target sound configuration.
  /// [looping] specifies if the audio should repeat indefinitely.
  /// [asAlarm] bypasses system silent/vibrate profiles on supported platforms.
  Future<void> ringDevice({
    required Map<String, dynamic> data
  });

  /// Terminates the active ringing state immediately.
  Future<void> stopRing();

  /// Exposes whether the device is currently emitting sound.
  bool get isRinging;
}