// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

class GamepadElementConfig {
  final String id;
  final double x; // Percentage from left (0.0 to 1.0)
  final double y; // Percentage from top (0.0 to 1.0)
  final double scale;
  final bool visible;

  const GamepadElementConfig({
    required this.id,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.visible = true,
  });

  GamepadElementConfig copyWith({
    double? x,
    double? y,
    double? scale,
    bool? visible,
  }) {
    return GamepadElementConfig(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'scale': scale,
      'visible': visible,
    };
  }

  factory GamepadElementConfig.fromJson(Map<String, dynamic> json) {
    return GamepadElementConfig(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      visible: json['visible'] as bool? ?? true,
    );
  }
}

class GamepadLayout {
  final Map<String, GamepadElementConfig> elements;

  const GamepadLayout({required this.elements});

  GamepadLayout copyWith({
    Map<String, GamepadElementConfig>? elements,
  }) {
    return GamepadLayout(
      elements: elements ?? Map.from(this.elements),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'elements': elements.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory GamepadLayout.fromJson(Map<String, dynamic> json) {
    final elementsMap = json['elements'] as Map<String, dynamic>? ?? {};
    final elements = elementsMap.map(
      (key, value) => MapEntry(
        key,
        GamepadElementConfig.fromJson(value as Map<String, dynamic>),
      ),
    );
    return GamepadLayout(elements: elements);
  }

  // Default layout approximations based on typical landscape mobile screen
  // These will be refined on first render if needed.
  static GamepadLayout get defaultLayout {
    return GamepadLayout(
      elements: {
        'l2': const GamepadElementConfig(id: 'l2', x: 0.05, y: 0.05),
        'l1': const GamepadElementConfig(id: 'l1', x: 0.05, y: 0.22),
        'r2': const GamepadElementConfig(id: 'r2', x: 0.85, y: 0.05),
        'r1': const GamepadElementConfig(id: 'r1', x: 0.85, y: 0.22),
        'back': const GamepadElementConfig(id: 'back', x: 0.40, y: 0.03),
        'select': const GamepadElementConfig(id: 'select', x: 0.48, y: 0.05),
        'start': const GamepadElementConfig(id: 'start', x: 0.58, y: 0.05),
        'dpad': const GamepadElementConfig(id: 'dpad', x: 0.05, y: 0.45),
        'actions': const GamepadElementConfig(id: 'actions', x: 0.75, y: 0.45),
        'left_analog': const GamepadElementConfig(id: 'left_analog', x: 0.28, y: 0.65),
        'l3_btn': const GamepadElementConfig(id: 'l3_btn', x: 0.02, y: 0.88),
        'right_analog': const GamepadElementConfig(id: 'right_analog', x: 0.60, y: 0.65),
        'r3_btn': const GamepadElementConfig(id: 'r3_btn', x: 0.90, y: 0.88),
      },
    ); }
}
