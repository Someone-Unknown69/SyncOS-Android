// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

class GamepadSettings {
  final bool enableHaptics;
  final double buttonOpacity;
  final double stickSensitivity;
  final double stickDeadzone;
  final int transmissionRateHz;

  const GamepadSettings({
    this.enableHaptics = true,
    this.buttonOpacity = 1.0,
    this.stickSensitivity = 1.0,
    this.stickDeadzone = 0.15,
    this.transmissionRateHz = 60,
  });

  GamepadSettings copyWith({
    bool? enableHaptics,
    double? buttonOpacity,
    double? stickSensitivity,
    double? stickDeadzone,
    int? transmissionRateHz,
  }) {
    return GamepadSettings(
      enableHaptics: enableHaptics ?? this.enableHaptics,
      buttonOpacity: buttonOpacity ?? this.buttonOpacity,
      stickSensitivity: stickSensitivity ?? this.stickSensitivity,
      stickDeadzone: stickDeadzone ?? this.stickDeadzone,
      transmissionRateHz: transmissionRateHz ?? this.transmissionRateHz,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableHaptics': enableHaptics,
      'buttonOpacity': buttonOpacity,
      'stickSensitivity': stickSensitivity,
      'stickDeadzone': stickDeadzone,
      'transmissionRateHz': transmissionRateHz,
    };
  }

  factory GamepadSettings.fromJson(Map<String, dynamic> json) {
    return GamepadSettings(
      enableHaptics: json['enableHaptics'] as bool? ?? true,
      buttonOpacity: (json['buttonOpacity'] as num?)?.toDouble() ?? 1.0,
      stickSensitivity: (json['stickSensitivity'] as num?)?.toDouble() ?? 1.0,
      stickDeadzone: (json['stickDeadzone'] as num?)?.toDouble() ?? 0.15,
      transmissionRateHz: json['transmissionRateHz'] as int? ?? 60,
    );
  }
}
