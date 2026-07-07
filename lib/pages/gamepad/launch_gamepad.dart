// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/gamepad/data/controller_service.dart';
import 'package:syncos_android/features/gamepad/domain/i_gamepad_state.dart';
import 'package:syncos_android/features/gamepad/provider/controller_service_provider.dart';
import 'package:syncos_android/features/gamepad/provider/gamepad_layout_provider.dart';
import 'package:syncos_android/features/gamepad/provider/gamepad_settings_provider.dart';
import 'package:syncos_android/features/gamepad/domain/gamepad_layout.dart';
import '../../theme/app_theme.dart';

class LaunchGamepad extends ConsumerStatefulWidget {
  const LaunchGamepad({super.key});

  @override
  ConsumerState<LaunchGamepad> createState() => _LaunchGamepadState();
}

class _LaunchGamepadState extends ConsumerState<LaunchGamepad> {
  late final ControllerService _controllerService;

  @override
  void initState() {
    super.initState();
    _controllerService = ref.read(controllerServiceProvider);
    _controllerService.start();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _controllerService.stop();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Widget _buildConfiguredElement({
    required String id,
    required GamepadLayout layout,
    required Size screenSize,
    required Widget child,
  }) {
    final config = layout.elements[id];
    if (config == null || !config.visible) return const SizedBox.shrink();

    final settings = ref.watch(gamepadSettingsProvider);

    return Positioned(
      left: config.x * screenSize.width,
      top: config.y * screenSize.height,
      child: Transform.scale(
        scale: config.scale,
        alignment: Alignment.topLeft,
        child: Opacity(
          opacity: settings.buttonOpacity,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final gamepadState = ref.read(gamepadStateProvider);
    final gamepadLayout = ref.watch(gamepadLayoutProvider);

    // Global Sizing
    const double btnSize = 55.0;
    const double analogRadius = 55.0;
    const double shoulderWidth = 90.0;
    const double shoulderHeight = 45.0;
    const double centerBtnWidth = 55.0;
    const double centerBtnHeight = 35.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background grids or anything else could be here

          // L2
          _buildConfiguredElement(
            id: 'l2', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "L2",
              onPressedDown: () => gamepadState.pressButton(GamepadButton.l2, true),
              onPressedUp: () => gamepadState.pressButton(GamepadButton.l2, false),
            ),
          ),
          // L1
          _buildConfiguredElement(
            id: 'l1', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "L1",
              onPressedDown: () => gamepadState.pressButton(GamepadButton.l1, true),
              onPressedUp: () => gamepadState.pressButton(GamepadButton.l1, false),
            ),
          ),
          // R2
          _buildConfiguredElement(
            id: 'r2', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "R2",
              onPressedDown: () => gamepadState.pressButton(GamepadButton.r2, true),
              onPressedUp: () => gamepadState.pressButton(GamepadButton.r2, false),
            ),
          ),
          // R1
          _buildConfiguredElement(
            id: 'r1', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "R1",
              onPressedDown: () => gamepadState.pressButton(GamepadButton.r1, true),
              onPressedUp: () => gamepadState.pressButton(GamepadButton.r1, false),
            ),
          ),

          // Back Button
          _buildConfiguredElement(
            id: 'back', layout: gamepadLayout, screenSize: size,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // SELECT
          _buildConfiguredElement(
            id: 'select', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(
              width: centerBtnWidth, height: centerBtnHeight, icon: Icons.view_headline_rounded,
              onPressedDown: () => gamepadState.pressButton(GamepadButton.select, true),
              onPressedUp: () => gamepadState.pressButton(GamepadButton.select, false),
            ),
          ),

          // START
          _buildConfiguredElement(
            id: 'start', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(
              width: centerBtnWidth, height: centerBtnHeight, icon: Icons.play_arrow_rounded,
              onPressedDown: () => gamepadState.pressButton(GamepadButton.start, true),
              onPressedUp: () => gamepadState.pressButton(GamepadButton.start, false),
            ),
          ),

          // D-PAD (LEFT CLUSTER)
          _buildConfiguredElement(
            id: 'dpad', layout: gamepadLayout, screenSize: size,
            child: SizedBox(
              width: btnSize * 3,
              height: btnSize * 3,
              child: Stack(
                children: [
                  Positioned(left: btnSize, top: 0, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_up_rounded, onPressedDown: () => gamepadState.pressButton(GamepadButton.dPadUp, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.dPadUp, false))),
                  Positioned(left: btnSize, top: btnSize * 2, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_down_rounded, onPressedDown: () => gamepadState.pressButton(GamepadButton.dPadDown, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.dPadDown, false))),
                  Positioned(left: 0, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_left_rounded, onPressedDown: () => gamepadState.pressButton(GamepadButton.dPadLeft, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.dPadLeft, false))),
                  Positioned(left: btnSize * 2, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_right_rounded, onPressedDown: () => gamepadState.pressButton(GamepadButton.dPadRight, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.dPadRight, false))),
                ],
              ),
            ),
          ),

          // ACTION BUTTONS (RIGHT CLUSTER)
          _buildConfiguredElement(
            id: 'actions', layout: gamepadLayout, screenSize: size,
            child: SizedBox(
              width: btnSize * 3,
              height: btnSize * 3,
              child: Stack(
                children: [
                  Positioned(left: btnSize, top: 0, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "△", isCircle: true, isPrimary: true, onPressedDown: () => gamepadState.pressButton(GamepadButton.actionUp, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.actionUp, false))),
                  Positioned(left: btnSize, top: btnSize * 2, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "✕", isCircle: true, isPrimary: true, onPressedDown: () => gamepadState.pressButton(GamepadButton.actionDown, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.actionDown, false))),
                  Positioned(left: 0, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "□", isCircle: true, isPrimary: true, onPressedDown: () => gamepadState.pressButton(GamepadButton.actionLeft, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.actionLeft, false))),
                  Positioned(left: btnSize * 2, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "○", isCircle: true, isPrimary: true, onPressedDown: () => gamepadState.pressButton(GamepadButton.actionRight, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.actionRight, false))),
                ],
              ),
            ),
          ),

          // Left Analog stick
          _buildConfiguredElement(
            id: 'left_analog', layout: gamepadLayout, screenSize: size,
            child: AnalogStick(
              radius: analogRadius,
              onStickChanged: (x, y) {
                gamepadState.setAxis(0, x);
                gamepadState.setAxis(1, y);
              },
              onStickPressed: () => gamepadState.pressButton(GamepadButton.l3, true),
              onStickReleased: () => gamepadState.pressButton(GamepadButton.l3, false),
            ),
          ),

          // L3 button
          _buildConfiguredElement(
            id: 'l3_btn', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(width: centerBtnWidth, height: centerBtnHeight, label: 'L3', onPressedDown: () => gamepadState.pressButton(GamepadButton.l3, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.l3, false)),
          ),

          // Right Analog stick
          _buildConfiguredElement(
            id: 'right_analog', layout: gamepadLayout, screenSize: size,
            child: AnalogStick(
              radius: analogRadius,
              onStickChanged: (x, y) {
                gamepadState.setAxis(2, x);
                gamepadState.setAxis(3, y);
              },
              onStickPressed: () => gamepadState.pressButton(GamepadButton.r3, true),
              onStickReleased: () => gamepadState.pressButton(GamepadButton.r3, false),
            ),
          ),

          // R3 button
          _buildConfiguredElement(
            id: 'r3_btn', layout: gamepadLayout, screenSize: size,
            child: GamepadButtonWidget(width: centerBtnWidth, height: centerBtnHeight, label: 'R3', onPressedDown: () => gamepadState.pressButton(GamepadButton.r3, true), onPressedUp: () => gamepadState.pressButton(GamepadButton.r3, false)),
          ),
        ],
      ),
    );
  }
}

class GamepadButtonWidget extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final String? label;
  final IconData? icon;
  final VoidCallback onPressedDown;
  final VoidCallback onPressedUp;
  final bool isPrimary;
  final bool isCircle;

  const GamepadButtonWidget({
    super.key,
    required this.width,
    required this.height,
    this.label,
    this.icon,
    required this.onPressedDown,
    required this.onPressedUp,
    this.isPrimary = false,
    this.isCircle = false,
  });

  @override
  ConsumerState<GamepadButtonWidget> createState() => _GamepadButtonWidgetState();
}

class _GamepadButtonWidgetState extends ConsumerState<GamepadButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine colors based on state
    Color buttonColor;
    if (_isPressed) {
      buttonColor = widget.isPrimary ? colorScheme.primary : colorScheme.outlineVariant;
    } else {
      buttonColor = widget.isPrimary ? colorScheme.primaryContainer : colorScheme.surfaceContainer;
    }

    Color contentColor;
    if (_isPressed) {
      contentColor = widget.isPrimary ? colorScheme.onPrimary : colorScheme.onSurface;
    } else {
      contentColor = widget.isPrimary ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Listener(
        onPointerDown: (_) {
          setState(() => _isPressed = true);
          final settings = ref.read(gamepadSettingsProvider);
          if (settings.enableHaptics) {
            HapticFeedback.lightImpact();
          }
          widget.onPressedDown();
        },
        onPointerUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressedUp();
        },
        onPointerCancel: (_) {
          setState(() => _isPressed = false);
          widget.onPressedUp();
        },
        child: Card(
          elevation: _isPressed ? 0 : 2,
          margin: EdgeInsets.zero,
          shape: widget.isCircle 
            ? CircleBorder(side: BorderSide(color: colorScheme.outlineVariant, width: _isPressed ? 2 : 1))
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                side: BorderSide(color: colorScheme.outlineVariant, width: _isPressed ? 2 : 1),
              ),
          clipBehavior: Clip.antiAlias,
          color: buttonColor,
          child: Center(
            child: widget.icon != null 
              ? Icon(
                  widget.icon, 
                  color: contentColor,
                  size: 24,
                )
              : Text(
                  widget.label ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: contentColor,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class AnalogStick extends ConsumerStatefulWidget {
  final double radius;
  final Function(double x, double y) onStickChanged;
  final VoidCallback? onStickPressed;
  final VoidCallback? onStickReleased;

  const AnalogStick({
    super.key,
    required this.radius,
    required this.onStickChanged,
    this.onStickPressed,
    this.onStickReleased,
  });

  @override
  ConsumerState<AnalogStick> createState() => _AnalogStickState();
}

class _AnalogStickState extends ConsumerState<AnalogStick> {
  Offset _stickPosition = Offset.zero;
  // True while a pan gesture is active — suppresses L3/R3 tap detection.
  bool _isPanning = false;
  // Tracks whether we've already fired the edge-zone haptic for this pan gesture.
  bool _hapticFired = false;

  static const double _hapticThreshold = 0.80; // 80% deflection triggers haptic

  void _updateStickPosition(Offset localPosition) {
    final center = Offset(widget.radius, widget.radius);
    final offsetFromCenter = localPosition - center;
    
    // Distance from the exact center point
    double distance = offsetFromCenter.distance;
    
    // Clamp stick range to outer boundary radius
    double maxDistance = widget.radius - 15; 

    Offset normalizedOffset = offsetFromCenter;
    if (distance > maxDistance) {
      normalizedOffset = (offsetFromCenter / distance) * maxDistance;
      distance = maxDistance;
    }

    setState(() {
      _stickPosition = normalizedOffset;
    });

    final settings = ref.read(gamepadSettingsProvider);

    // Emits values mapping nicely between -1.0 and 1.0
    double rawX = normalizedOffset.dx / maxDistance;
    double rawY = normalizedOffset.dy / maxDistance;

    // Apply deadzone and sensitivity
    final deadzone = settings.stickDeadzone;
    final sensitivity = settings.stickSensitivity;

    double inputMagnitude = Offset(rawX, rawY).distance;
    double vectorX = 0.0;
    double vectorY = 0.0;

    if (inputMagnitude > deadzone) {
      // Normalize and scale magnitude
      double scaledMagnitude = ((inputMagnitude - deadzone) / (1.0 - deadzone)) * sensitivity;
      scaledMagnitude = scaledMagnitude.clamp(0.0, 1.0);
      
      vectorX = (rawX / inputMagnitude) * scaledMagnitude;
      vectorY = (rawY / inputMagnitude) * scaledMagnitude;
    }

    // Y-axis inversion is handled exclusively by the Linux driver (ABS_Y/ABS_RY negation).
    // Do NOT invert here, doing so causes a double-inversion that cancels out the driver's correction.
    widget.onStickChanged(vectorX, vectorY);

    // Fire a single haptic buzz when the stick first reaches the edge zone,
    // and reset once it returns to centre so subsequent pushes fire again.
    final deflection = (distance / maxDistance).clamp(0.0, 1.0);
    if (deflection >= _hapticThreshold && !_hapticFired) {
      if (settings.enableHaptics) {
        HapticFeedback.lightImpact();
      }
      _hapticFired = true;
    } else if (deflection < _hapticThreshold * 0.5) {
      _hapticFired = false; // reset when stick returns near centre
    }
  }

  void _resetStick() {
    setState(() {
      _stickPosition = Offset.zero;
    });
    _hapticFired = false;
    widget.onStickChanged(0.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Listener is the outer wrapper so pointer-down/up always fires for L3/R3,
    // independent of whether the user is also panning — matching real stick-click behaviour.
    return Listener(
      onPointerDown: (_) {
        // Don't fire yet, wait to see if this is a tap or the start of a pan.
      },
      onPointerUp: (_) {
        // Only treat as a stick-click if no pan was ever started.
        if (!_isPanning) {
          final settings = ref.read(gamepadSettingsProvider);
          if (settings.enableHaptics) {
            HapticFeedback.lightImpact();
          }
          widget.onStickPressed?.call();
          widget.onStickReleased?.call();
        }
      },
      onPointerCancel: (_) {
        _isPanning = false;
      },
      child: GestureDetector(
        onPanStart: (_) => _isPanning = true,
        onPanUpdate: (details) => _updateStickPosition(details.localPosition),
        onPanEnd: (_) {
          _isPanning = false;
          _resetStick();
        },
        onPanCancel: () {
          _isPanning = false;
          _resetStick();
        },
        child: Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.onSurface.withValues(alpha: 0.08),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: widget.radius - 20 + _stickPosition.dx,
              top: widget.radius - 20 + _stickPosition.dy,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
