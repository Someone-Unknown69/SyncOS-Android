// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/gamepad/domain/gamepad_layout.dart';
import 'package:syncos_android/features/gamepad/provider/gamepad_layout_provider.dart';
import 'package:syncos_android/pages/gamepad/launch_gamepad.dart';

class ConfigureGamepadLayout extends ConsumerStatefulWidget {
  const ConfigureGamepadLayout({super.key});

  @override
  ConsumerState<ConfigureGamepadLayout> createState() => _ConfigureGamepadLayoutState();
}

class _ConfigureGamepadLayoutState extends ConsumerState<ConfigureGamepadLayout> {
  GamepadLayout _currentLayout = GamepadLayout.defaultLayout;
  String? _selectedElementId;

  @override
  void initState() {
    super.initState();
    // Copy the current layout from the provider for editing
    _currentLayout = ref.read(gamepadLayoutProvider);
    
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

  void _saveLayout() {
    // We update the state by dispatching each element to the provider, 
    // or we can add a 'saveLayout' method to the provider. Let's update each.
    for (final element in _currentLayout.elements.values) {
      ref.read(gamepadLayoutProvider.notifier).updateElement(element);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Layout saved successfully!')),
    );
    Navigator.pop(context);
  }

  void _resetLayout() {
    setState(() {
      _currentLayout = GamepadLayout.defaultLayout;
      _selectedElementId = null;
    });
  }

  void _updateElement(GamepadElementConfig newConfig) {
    setState(() {
      final updatedElements = Map<String, GamepadElementConfig>.from(_currentLayout.elements);
      updatedElements[newConfig.id] = newConfig;
      _currentLayout = _currentLayout.copyWith(elements: updatedElements);
    });
  }

  void _updateElementSilently(GamepadElementConfig newConfig) {
    final updatedElements = Map<String, GamepadElementConfig>.from(_currentLayout.elements);
    updatedElements[newConfig.id] = newConfig;
    _currentLayout = _currentLayout.copyWith(elements: updatedElements);
  }

  Widget _buildConfigurableElement({
    required String id,
    required Widget child,
    required Size screenSize,
  }) {
    final config = _currentLayout.elements[id] ?? GamepadElementConfig(id: id, x: 0.5, y: 0.5, visible: false);
    
    if (!config.visible) return const SizedBox.shrink();

    final isSelected = _selectedElementId == id;

    return ConfigurableGamepadElement(
      key: ValueKey(id),
      config: config,
      screenSize: screenSize,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedElementId = isSelected ? null : id;
        });
      },
      onDragUpdate: _updateElementSilently,
      onDragEnd: _updateElement,
      child: child,
    );
  }

  Widget _buildEditorPanel() {
    if (_selectedElementId == null) return const SizedBox.shrink();

    final config = _currentLayout.elements[_selectedElementId!];
    if (config == null) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Editing: ${config.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Size:'),
                  Slider(
                    value: config.scale,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (val) {
                      _updateElement(config.copyWith(scale: val));
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _updateElement(config.copyWith(visible: false));
                      setState(() => _selectedElementId = null);
                    },
                    icon: const Icon(Icons.visibility_off),
                    label: const Text('Hide'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedElementId = null),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showAddElementsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Elements'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              final hiddenElements = _currentLayout.elements.values.where((e) => !e.visible).toList();
              if (hiddenElements.isEmpty) {
                return const Text('No hidden elements.');
              }
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hiddenElements.length,
                  itemBuilder: (context, index) {
                    final element = hiddenElements[index];
                    return ListTile(
                      title: Text(element.id),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _updateElement(element.copyWith(visible: true));
                          Navigator.pop(context);
                          _showAddElementsDialog(); // Re-open to refresh or just pop
                        },
                      ),
                    );
                  },
                ),
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    // Same sizing constants as in launch_gamepad
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
          // Background grid (optional)
          CustomPaint(
            size: size,
            painter: GridPainter(color: colorScheme.onSurface.withValues(alpha: 0.1)),
          ),

          // Elements
          _buildConfigurableElement(
            id: 'l2',
            screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "L2",
              onPressedDown: () {}, onPressedUp: () {},
            ),
          ),
          _buildConfigurableElement(
            id: 'l1',
            screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "L1",
              onPressedDown: () {}, onPressedUp: () {},
            ),
          ),
          _buildConfigurableElement(
            id: 'r2',
            screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "R2",
              onPressedDown: () {}, onPressedUp: () {},
            ),
          ),
          _buildConfigurableElement(
            id: 'r1',
            screenSize: size,
            child: GamepadButtonWidget(
              width: shoulderWidth, height: shoulderHeight, label: "R1",
              onPressedDown: () {}, onPressedUp: () {},
            ),
          ),
          _buildConfigurableElement(
            id: 'back',
            screenSize: size,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () {},
            ),
          ),
          _buildConfigurableElement(
            id: 'select',
            screenSize: size,
            child: GamepadButtonWidget(
              width: centerBtnWidth, height: centerBtnHeight, icon: Icons.view_headline_rounded,
              onPressedDown: () {}, onPressedUp: () {},
            ),
          ),
          _buildConfigurableElement(
            id: 'start',
            screenSize: size,
            child: GamepadButtonWidget(
              width: centerBtnWidth, height: centerBtnHeight, icon: Icons.play_arrow_rounded,
              onPressedDown: () {}, onPressedUp: () {},
            ),
          ),
          _buildConfigurableElement(
            id: 'dpad',
            screenSize: size,
            child: SizedBox(
              width: btnSize * 3,
              height: btnSize * 3,
              child: Stack(
                children: [
                  Positioned(left: btnSize, top: 0, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_up_rounded, onPressedDown: () {}, onPressedUp: () {})),
                  Positioned(left: btnSize, top: btnSize * 2, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_down_rounded, onPressedDown: () {}, onPressedUp: () {})),
                  Positioned(left: 0, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_left_rounded, onPressedDown: () {}, onPressedUp: () {})),
                  Positioned(left: btnSize * 2, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, icon: Icons.keyboard_arrow_right_rounded, onPressedDown: () {}, onPressedUp: () {})),
                ],
              ),
            ),
          ),
          _buildConfigurableElement(
            id: 'actions',
            screenSize: size,
            child: SizedBox(
              width: btnSize * 3,
              height: btnSize * 3,
              child: Stack(
                children: [
                  Positioned(left: btnSize, top: 0, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "△", isCircle: true, isPrimary: true, onPressedDown: () {}, onPressedUp: () {})),
                  Positioned(left: btnSize, top: btnSize * 2, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "✕", isCircle: true, isPrimary: true, onPressedDown: () {}, onPressedUp: () {})),
                  Positioned(left: 0, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "□", isCircle: true, isPrimary: true, onPressedDown: () {}, onPressedUp: () {})),
                  Positioned(left: btnSize * 2, top: btnSize, child: GamepadButtonWidget(width: btnSize, height: btnSize, label: "○", isCircle: true, isPrimary: true, onPressedDown: () {}, onPressedUp: () {})),
                ],
              ),
            ),
          ),
          _buildConfigurableElement(
            id: 'left_analog',
            screenSize: size,
            child: AnalogStick(radius: analogRadius, onStickChanged: (x,y){}),
          ),
          _buildConfigurableElement(
            id: 'l3_btn',
            screenSize: size,
            child: GamepadButtonWidget(width: centerBtnWidth, height: centerBtnHeight, label: 'L3', onPressedDown: () {}, onPressedUp: () {}),
          ),
          _buildConfigurableElement(
            id: 'right_analog',
            screenSize: size,
            child: AnalogStick(radius: analogRadius, onStickChanged: (x,y){}),
          ),
          _buildConfigurableElement(
            id: 'r3_btn',
            screenSize: size,
            child: GamepadButtonWidget(width: centerBtnWidth, height: centerBtnHeight, label: 'R3', onPressedDown: () {}, onPressedUp: () {}),
          ),

          // Editor overlay
          _buildEditorPanel(),

          // Toolbar
          DraggableToolbar(
            screenSize: size,
            onBack: () => Navigator.pop(context),
            onReset: _resetLayout,
            onAddElements: _showAddElementsDialog,
            onSave: _saveLayout,
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConfigurableGamepadElement extends StatefulWidget {
  final GamepadElementConfig config;
  final Widget child;
  final Size screenSize;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<GamepadElementConfig> onDragUpdate;
  final ValueChanged<GamepadElementConfig> onDragEnd;

  const ConfigurableGamepadElement({
    super.key,
    required this.config,
    required this.child,
    required this.screenSize,
    required this.isSelected,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<ConfigurableGamepadElement> createState() => _ConfigurableGamepadElementState();
}

class _ConfigurableGamepadElementState extends State<ConfigurableGamepadElement> {
  late double _x;
  late double _y;
  Offset? _dragStartGlobalPosition;
  double? _dragStartElementX;
  double? _dragStartElementY;

  @override
  void initState() {
    super.initState();
    _x = widget.config.x;
    _y = widget.config.y;
  }

  @override
  void didUpdateWidget(ConfigurableGamepadElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.x != _x) {
      _x = widget.config.x;
    }
    if (widget.config.y != _y) {
      _y = widget.config.y;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: _x * widget.screenSize.width,
      top: _y * widget.screenSize.height,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (details) {
          _dragStartGlobalPosition = details.globalPosition;
          _dragStartElementX = _x;
          _dragStartElementY = _y;
        },
        onPanUpdate: (details) {
          if (_dragStartGlobalPosition == null ||
              _dragStartElementX == null ||
              _dragStartElementY == null) {
            return;
          }
          final delta = details.globalPosition - _dragStartGlobalPosition!;
          double newX = _dragStartElementX! + (delta.dx / widget.screenSize.width);
          double newY = _dragStartElementY! + (delta.dy / widget.screenSize.height);
          
          setState(() {
            _x = newX.clamp(0.0, 1.0);
            _y = newY.clamp(0.0, 1.0);
          });
          
          widget.onDragUpdate(widget.config.copyWith(x: _x, y: _y));
        },
        onPanEnd: (_) {
          _dragStartGlobalPosition = null;
          _dragStartElementX = null;
          _dragStartElementY = null;
          widget.onDragEnd(widget.config.copyWith(x: _x, y: _y));
        },
        onPanCancel: () {
          _dragStartGlobalPosition = null;
          _dragStartElementX = null;
          _dragStartElementY = null;
          widget.onDragEnd(widget.config.copyWith(x: _x, y: _y));
        },
        child: Transform.scale(
          scale: widget.config.scale,
          child: Container(
            decoration: widget.isSelected
                ? BoxDecoration(
                    border: Border.all(color: colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: AbsorbPointer(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class DraggableToolbar extends StatefulWidget {
  final Size screenSize;
  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onAddElements;
  final VoidCallback onSave;

  const DraggableToolbar({
    super.key,
    required this.screenSize,
    required this.onBack,
    required this.onReset,
    required this.onAddElements,
    required this.onSave,
  });

  @override
  State<DraggableToolbar> createState() => _DraggableToolbarState();
}

class _DraggableToolbarState extends State<DraggableToolbar> {
  Offset? _toolbarPosition;
  Offset? _dragStartGlobalPosition;
  Offset? _dragStartToolbarPosition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultPosition = Offset(widget.screenSize.width - 328, 16);
    final currentPosition = _toolbarPosition ?? defaultPosition;

    return Positioned(
      left: currentPosition.dx,
      top: currentPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          _dragStartGlobalPosition = details.globalPosition;
          _dragStartToolbarPosition = currentPosition;
        },
        onPanUpdate: (details) {
          if (_dragStartGlobalPosition == null || _dragStartToolbarPosition == null) {
            return;
          }
          final delta = details.globalPosition - _dragStartGlobalPosition!;
          setState(() {
            _toolbarPosition = _dragStartToolbarPosition! + delta;
          });
        },
        onPanEnd: (_) {
          _dragStartGlobalPosition = null;
          _dragStartToolbarPosition = null;
        },
        onPanCancel: () {
          _dragStartGlobalPosition = null;
          _dragStartToolbarPosition = null;
        },
        child: Card(
          elevation: 4,
          color: colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_indicator, color: Colors.grey),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'layout_config_back',
                  onPressed: widget.onBack,
                  tooltip: 'Go Back',
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'reset',
                  onPressed: widget.onReset,
                  tooltip: 'Reset to Default',
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'add',
                  onPressed: widget.onAddElements,
                  tooltip: 'Add Hidden Elements',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.extended(
                  heroTag: 'save',
                  onPressed: widget.onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
