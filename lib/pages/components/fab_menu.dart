import 'dart:math' as math;
import 'package:flutter/material.dart';

class FABOption {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  FABOption({required this.icon, required this.onPressed, this.color});
}

class FABbutton extends StatefulWidget {
  final List<FABOption> options;
  final String labelOpen;
  final String labelClose;

  const FABbutton({
    super.key,
    required this.options,
    this.labelOpen = 'Open',
    this.labelClose = 'Close',
  });

  @override
  State<FABbutton> createState() => _FABbuttonState();
}

class _FABbuttonState extends State<FABbutton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      _open ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none, 
        children: [
          _buildTapToCloseFab(),
          ..._buildVerticalActionButtons(),
          _buildTapToOpenFab(),

          
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return AnimatedOpacity(
      opacity: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        heroTag: 'fab_close',
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        onPressed: _toggle,
        label: Text(widget.labelClose, style: const TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedOpacity(
        opacity: _open ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: FloatingActionButton.extended(
          heroTag: 'fab_main',
          onPressed: _toggle,
          label: Text(widget.labelOpen, style: const TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  List<Widget> _buildVerticalActionButtons() {
    return List.generate(widget.options.length, (i) {
      final option = widget.options[i];
      return _ExpandingActionButton(
        directionInDegrees: 90.0, 
        maxDistance: (i + 1) * 60.0,
        progress: _expandAnimation,
        child: _ActionButton(
          icon: Icon(option.icon),
          color: option.color ?? Theme.of(context).colorScheme.primary,
          onPressed: () {
            _toggle();
            option.onPressed();
          },
        ),
      );
    });
  }
}

class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    this.onPressed,
    required this.icon,
    required this.color,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: color,
      ),
    );
  }
}