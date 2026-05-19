import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/usb_controller.dart';
import '../../theme/app_theme.dart';

class ControllerPage extends StatelessWidget {
  const ControllerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Remote Controller")),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.padding),
        children: [
          const Text("Select Mode", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing),
          
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.sports_esports, color: Theme.of(context).colorScheme.primary),
              title: const Text("Launch Gamepad", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamePage()),
                );
              },
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing / 2),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.gamepad, color: Theme.of(context).colorScheme.primary),
              title: const Text("Configure Layout", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { /* Future configuration logic */ },
            ),
          ),

          const SizedBox(height: AppTheme.spacing / 2),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
              title: const Text("Gamepad Settings", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { /* Future configuration logic */ },
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing * 4),
          Text(
            "Connect your mobile device to your laptop/PC with USB for lower latency",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          
          
        ],
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final _usbControllerService = USBControllerService();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
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
              onPressedDown: () => _usbControllerService.sendEvent('L2', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('L2', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('L1', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('L1', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('R2', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('R2', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('R1', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('R1', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('SELECT', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('SELECT', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('START', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('START', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('UP', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('UP', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('DOWN', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('DOWN', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('LEFT', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('LEFT', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('RIGHT', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('RIGHT', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('TRIANGLE', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('TRIANGLE', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('CROSS', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('CROSS', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('SQUARE', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('SQUARE', 'up'),
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
              onPressedDown: () => _usbControllerService.sendEvent('CIRCLE', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('CIRCLE', 'up'),
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