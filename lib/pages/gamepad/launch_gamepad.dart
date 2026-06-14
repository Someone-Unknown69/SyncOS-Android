// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/gamepad/gamepad_event_sender.dart';
import '../../core/network/provider/connection_provider.dart';
import '../../theme/app_theme.dart';

class LaunchGamepad extends ConsumerStatefulWidget {
  const LaunchGamepad({super.key});

  @override
  ConsumerState<LaunchGamepad> createState() => _LaunchGamepadState();
}

class _LaunchGamepadState extends ConsumerState<LaunchGamepad> {
  late final USBControllerService _usbControllerService;

  @override
  void initState() {
    super.initState();
    _usbControllerService = USBControllerService(ref.read(connectionManagerProvider));
    _usbControllerService.sendEvent('start', {});
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _usbControllerService.sendEvent('stop', {});
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    // =========================================================================
    //                  CONFIGURATION & LAYOUT VALUES 
    //(Tweak these to change the entire UI, will make it modifiable in future)
    // =========================================================================
    
    // Global Sizing
    const double btnSize = 55.0;       // Diameter of D-pad and Action buttons
    const double analogRadius = 55.0;  // Radius of the Analog outer ring

    // Shoulder/Trigger Buttons Configuration
    const double shoulderWidth = 90.0;
    const double shoulderHeight = 45.0;
    const double shoulderTopPadding = 15.0;
    const double shoulderSidePadding = 20.0;
    const double shoulderGap = 10.0;   // Vertical space between L2/L1 and R2/R1

    // Cluster Positioning (D-pad & Actions)
    const double clusterSideOffset = 45.0; // Margin from left/right edges
    const double clusterBottomOffset = 100.0; // Margin from bottom

    const double analogXOffset = 195; // margin from left/right
    const double analogBottomOffset = 20.0; // margin from bottom

    // Central Buttons (Select, Start, Back)
    const double centerTopPadding = 25.0;
    const double centerBtnWidth = 55.0;
    const double centerBtnHeight = 35.0;
    const double centerGap = 40.0;
    
    // =========================================================================
    // DERIVED COMPUTATIONS (Do not modify manually unless tweaking math)
    // =========================================================================
    final double halfWidth = size.width / 2;
    final double lowerShoulderTop = shoulderTopPadding + shoulderHeight + shoulderGap;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // --- SHOULDER BUTTONS ---

          // L2
          Positioned(
            top: shoulderTopPadding,
            left: shoulderSidePadding,
            child: GamepadButton(
              width: shoulderWidth,
              height: shoulderHeight,
              label: "L2",
              onPressedDown: () => _usbControllerService.sendEvent('triggers', {'l2': 1.0, 'r2': _usbControllerService.currentR2}),
              onPressedUp: () => _usbControllerService.sendEvent('triggers', {'l2': 0.0, 'r2': _usbControllerService.currentR2})
            ),
          ),
          // L1
          Positioned(
            top: lowerShoulderTop,
            left: shoulderSidePadding,
            child: GamepadButton(
              width: shoulderWidth,
              height: shoulderHeight,
              label: "L1",
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'L1'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'L1'}),
            ),
          ),
          // R2
          Positioned(
            top: shoulderTopPadding,
            right: shoulderSidePadding,
            child: GamepadButton(
              width: shoulderWidth,
              height: shoulderHeight,
              label: "R2",
              onPressedDown: () => _usbControllerService.sendEvent('triggers', {'l2': _usbControllerService.currentL2, 'r2': 1.0}),
              onPressedUp: () => _usbControllerService.sendEvent('triggers', {'l2': _usbControllerService.currentL2, 'r2': 0.0}),
            ),
          ),
          // R1
          Positioned(
            top: lowerShoulderTop,
            right: shoulderSidePadding,
            child: GamepadButton(
              width: shoulderWidth,
              height: shoulderHeight,
              label: "R1",
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'R1'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'R1'}),
            ),
          ),

          // --- CENTRAL BUTTONS ---
          
          // Back Button
          Positioned(
            top: shoulderTopPadding,
            left: halfWidth - (centerBtnWidth + centerGap * 2),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // SELECT
          Positioned(
            top: centerTopPadding,
            left: halfWidth - centerBtnWidth - (centerGap / 2),
            child: GamepadButton(
              width: centerBtnWidth,
              height: centerBtnHeight,
              icon: Icons.view_headline_rounded,
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'SELECT'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'SELECT'}),
            ),
          ),
          // START
          Positioned(
            top: centerTopPadding,
            left: halfWidth + (centerGap / 2),
            child: GamepadButton(
              width: centerBtnWidth,
              height: centerBtnHeight,
              icon: Icons.play_arrow_rounded,
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'START'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'START'}),
            ),
          ),

          // --- D-PAD (LEFT CLUSTER) ---
          
          // UP
          Positioned(
            left: clusterSideOffset + btnSize,
            bottom: clusterBottomOffset + (btnSize * 1.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              icon: Icons.keyboard_arrow_up_rounded,
              onPressedDown: () => _updateDpadKey('DPAD_UP', 'down'),
              onPressedUp: () => _updateDpadKey('DPAD_UP', 'up'),
            ),
          ),
          // DOWN
          Positioned(
            left: clusterSideOffset + btnSize,
            bottom: clusterBottomOffset - (btnSize * 0.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              icon: Icons.keyboard_arrow_down_rounded,
              onPressedDown: () => _updateDpadKey('DPAD_DOWN', 'down'),
              onPressedUp: () => _updateDpadKey('DPAD_DOWN', 'up'),
            ),
          ),
          // LEFT
          Positioned(
            left: clusterSideOffset,
            bottom: clusterBottomOffset + (btnSize * 0.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              icon: Icons.keyboard_arrow_left_rounded,
              onPressedDown: () => _updateDpadKey('DPAD_LEFT', 'down'),
              onPressedUp: () => _updateDpadKey('DPAD_LEFT', 'up'),
            ),
          ),
          // RIGHT
          Positioned(
            left: clusterSideOffset + (btnSize * 2),
            bottom: clusterBottomOffset + (btnSize * 0.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              icon: Icons.keyboard_arrow_right_rounded,
              onPressedDown: () => _updateDpadKey('DPAD_RIGHT', 'down'),
              onPressedUp: () => _updateDpadKey('DPAD_RIGHT', 'up'),
            ),
          ),

          // --- ACTION BUTTONS (RIGHT CLUSTER) ---
          
          // TRIANGLE
          Positioned(
            right: clusterSideOffset + btnSize,
            bottom: clusterBottomOffset + (btnSize * 1.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              label: "△",
              isCircle: true,
              isPrimary: true,
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'TRIANGLE'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'TRIANGLE'}),
            ),
          ),
          // CROSS
          Positioned(
            right: clusterSideOffset + btnSize,
            bottom: clusterBottomOffset - (btnSize * 0.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              label: "✕",
              isCircle: true,
              isPrimary: true,
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'CROSS'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'CROSS'}),
            ),
          ),
          // SQUARE
          Positioned(
            right: clusterSideOffset + (btnSize * 2),
            bottom: clusterBottomOffset + (btnSize * 0.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              label: "□",
              isCircle: true,
              isPrimary: true,
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'SQUARE'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'SQUARE'}),
            ),
          ),
          // CIRCLE
          Positioned(
            right: clusterSideOffset,
            bottom: clusterBottomOffset + (btnSize * 0.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              label: "○",
              isCircle: true,
              isPrimary: true,
              onPressedDown: () => _usbControllerService.sendEvent('down', {'button': 'CIRCLE'}),
              onPressedUp: () => _usbControllerService.sendEvent('up', {'button': 'CIRCLE'}),
            ),
          ),

          // --- ANALOG STICKS ---
          
          // Left Analog
          Positioned(
            left: analogXOffset,
            bottom: analogBottomOffset,
            child: AnalogStick(
              radius: analogRadius,
              onStickChanged: (x, y) {
                _usbControllerService.sendAnalog('left_analog', x, y);
              },
            ),
          ),
          // Right Analog
          Positioned(
            right: analogXOffset,
            bottom: analogBottomOffset,
            child: AnalogStick(
              radius: analogRadius,
              onStickChanged: (x, y) {
                _usbControllerService.sendAnalog('right_analog', x, y);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateDpadKey(String key, String action) {
    if (action == 'down') {
      _usbControllerService.setPressedState(key, true);
    } else {
      _usbControllerService.setPressedState(key, false);
    }
    int x = 0;
    int y = 0;
    if (_usbControllerService.isPressed('DPAD_LEFT')) x -= 1;
    if (_usbControllerService.isPressed('DPAD_RIGHT')) x += 1;
    if (_usbControllerService.isPressed('DPAD_UP')) y -= 1;
    if (_usbControllerService.isPressed('DPAD_DOWN')) y += 1;

    _usbControllerService.sendEvent('dpad', {
      'x': x,
      'y': y,
    });
  }
}

class GamepadButton extends StatefulWidget {
  final double width;
  final double height;
  final String? label;
  final IconData? icon;
  final VoidCallback onPressedDown;
  final VoidCallback onPressedUp;
  final bool isPrimary;
  final bool isCircle;

  const GamepadButton({
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
  State<GamepadButton> createState() => _GamepadButtonState();
}

class _GamepadButtonState extends State<GamepadButton> {
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
          HapticFeedback.lightImpact();
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

class AnalogStick extends StatefulWidget {
  final double radius;
  final Function(double x, double y) onStickChanged;

  const AnalogStick({
    super.key,
    required this.radius,
    required this.onStickChanged,
  });

  @override
  State<AnalogStick> createState() => _AnalogStickState();
}

class _AnalogStickState extends State<AnalogStick> {
  Offset _stickPosition = Offset.zero;

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

    // Emits values mapping nicely between -1.0 and 1.0
    double vectorX = normalizedOffset.dx / maxDistance;
    double vectorY = normalizedOffset.dy / maxDistance;
    widget.onStickChanged(vectorX, -vectorY); // Invert Y to match traditional joystick standards
  }

  void _resetStick() {
    setState(() {
      _stickPosition = Offset.zero;
    });
    widget.onStickChanged(0.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanUpdate: (details) => _updateStickPosition(details.localPosition),
      onPanEnd: (_) => _resetStick(),
      onPanCancel: () => _resetStick(),
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
    );
  }
}