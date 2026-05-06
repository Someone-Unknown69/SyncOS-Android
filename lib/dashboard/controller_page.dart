import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/usb_controller.dart';

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
    
    // Force Horizontal (Landscape) Orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide Status Bar and Navigation Bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Reset Orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Show Status Bar and Navigation Bar again
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    
    // Layout Constants
    const double btnSize = 65;
    const double padOffset = 50;
    const double shoulderWidth = 100;
    const double shoulderHeight = 50;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // --- SHOULDER BUTTONS (TOP) ---
          
          // L2
          Positioned(
            top: 20,
            left: 20,
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
            top: 80,
            left: 20,
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
            top: 20,
            right: 20,
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
            top: 80,
            right: 20,
            child: GamepadButton(
              width: shoulderWidth,
              height: shoulderHeight,
              label: "R1",
              onPressedDown: () => _usbControllerService.sendEvent('R1', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('R1', 'up'),
            ),
          ),

          // --- CENTRAL BUTTONS ---
          
          // Back Button (Moved to top center-ish)
          Positioned(
            top: 20,
            left: size.width / 2 - 120,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // SELECT
          Positioned(
            top: 30,
            left: size.width / 2 - 70,
            child: GamepadButton(
              width: 60,
              height: 40,
              icon: Icons.view_headline_rounded,
              onPressedDown: () => _usbControllerService.sendEvent('SELECT', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('SELECT', 'up'),
            ),
          ),
          // START
          Positioned(
            top: 30,
            left: size.width / 2 + 10,
            child: GamepadButton(
              width: 60,
              height: 40,
              icon: Icons.play_arrow_rounded,
              onPressedDown: () => _usbControllerService.sendEvent('START', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('START', 'up'),
            ),
          ),


          // --- D-PAD (LEFT) ---
          
          // UP
          Positioned(
            left: padOffset + btnSize,
            bottom: padOffset + (btnSize * 1.5),
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
            left: padOffset + btnSize,
            bottom: padOffset - (btnSize * 0.5),
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
            left: padOffset,
            bottom: padOffset + (btnSize * 0.5),
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
            left: padOffset + (btnSize * 2),
            bottom: padOffset + (btnSize * 0.5),
            child: GamepadButton(
              width: btnSize,
              height: btnSize,
              icon: Icons.keyboard_arrow_right_rounded,
              onPressedDown: () => _usbControllerService.sendEvent('RIGHT', 'down'),
              onPressedUp: () => _usbControllerService.sendEvent('RIGHT', 'up'),
            ),
          ),


          // --- ACTION BUTTONS (RIGHT) ---
          
          // TRIANGLE (North)
          Positioned(
            right: padOffset + btnSize,
            bottom: padOffset + (btnSize * 1.5),
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
          // CROSS (South)
          Positioned(
            right: padOffset + btnSize,
            bottom: padOffset - (btnSize * 0.5),
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
          // SQUARE (West)
          Positioned(
            right: padOffset + (btnSize * 2),
            bottom: padOffset + (btnSize * 0.5),
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
          // CIRCLE (East)
          Positioned(
            right: padOffset,
            bottom: padOffset + (btnSize * 0.5),
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