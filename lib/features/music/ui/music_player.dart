import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/provider/connection_provider.dart';
import '../provider/remote_media_state.dart';
import '../../../theme/app_theme.dart';

// -------------------------------      Music Widget     -------------------------------------------

class MusicThemeService {
  /// Generates a Material 3 ColorScheme directly from an image.
  /// This uses the native Flutter algorithm to ensure harmonious tones.
  static Future<ColorScheme> generate(ImageProvider image, Brightness brightness) async {
    try {
      return await ColorScheme.fromImageProvider(
        provider: image,
        brightness: brightness,
      );
    } catch (e) {
      // Fallback if the image fails to load or extract
      return ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4), // Material 3 baseline purple
        brightness: brightness,
      );
    }
  }
}

class MusicPlayerWidget extends ConsumerStatefulWidget {
  const MusicPlayerWidget({super.key});

  @override
  ConsumerState<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends ConsumerState<MusicPlayerWidget> {
  ColorScheme? _dynamicScheme;
  String _lastImagePath = '';

  @override
  void initState() {
    super.initState();
    final info = ref.read(musicProvider);
    _lastImagePath = info.albumArtBase64;
    _updateTheme(info.albumArtBase64);
  }

  Future<void> _updateTheme(String imagePath) async {
    ImageProvider provider;
    if (imagePath != 'N/A' && imagePath.length > 50) {
      try {
        Uint8List bytes = base64Decode(imagePath);
        try {
          bytes = Uint8List.fromList(gzip.decode(bytes));
        } catch (_) {} // ignore if not gzipped
        provider = MemoryImage(bytes);
      } catch (e) {
        provider = const AssetImage('assets/images/album2.png');
      }
    } else {
      provider = const AssetImage('assets/images/album2.png');
    }

    final scheme = await MusicThemeService.generate(provider, Brightness.dark);
    if (mounted) {
      setState(() => _dynamicScheme = scheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(musicProvider);
    final manager = ref.read(connectionManagerProvider);

    // Detect album art change and refresh theme
    if (info.albumArtBase64 != _lastImagePath) {
      _lastImagePath = info.albumArtBase64;
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateTheme(info.albumArtBase64));
    }

    Uint8List? imageBytes;
    final imagePath = info.albumArtBase64;
    if (imagePath != 'N/A' && imagePath.length > 50) {
      try {
        imageBytes = base64Decode(imagePath);
        try {
          imageBytes = Uint8List.fromList(gzip.decode(imageBytes));
        } catch (_) {}
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
      }
    }

    final statusStr = info.status ? 'Playing' : 'Paused';
    final theme = _dynamicScheme ?? Theme.of(context).colorScheme;

    return Theme(
      data: ThemeData(useMaterial3: true, colorScheme: theme),
      child: Builder(builder: (context) {
        final localTheme = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.all(AppTheme.spacing / 2),
          height: 200,
          clipBehavior: Clip.antiAlias,

          decoration: BoxDecoration(
            color: localTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.musicPlayerRadius),
          ),
          
          child: Stack(
            children: [
              Positioned.fill(
                child: imageBytes != null
                  ? SizedBox.expand(
                      child: Image.memory(
                        imageBytes, 
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  : Container(color: localTheme.surfaceContainer),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        localTheme.surface.withValues(alpha: 1.0),
                        localTheme.scrim.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),

              // Layout Content
              Padding(
                padding: const EdgeInsets.all(AppTheme.padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: 
                          _TrackInfo(
                            name: info.title,
                            artist: info.artist,
                            theme: localTheme,
                          ),
                        ),

                        // Play/Pause button
                        IconButton(
                          onPressed: () {
                            manager.send('music', 'control', {'method': 'play_pause'});
                          },
                          icon: Icon(
                            statusStr == 'Playing'
                                ? Icons.pause_outlined
                                : Icons.play_arrow_outlined,
                            size: 25,
                          ),
                          color: theme.primaryContainer,
                          style: IconButton.styleFrom(
                            backgroundColor: theme.onPrimaryContainer,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(AppTheme.padding),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: 
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                            child: MusicProgressSlider(
                              theme: theme,
                              duration: info.duration.toDouble(),
                              position: info.position.toDouble(),
                              status: statusStr,
                            ),
                          ),
                        ),
                        
                        _ControlButtons(
                          theme: localTheme,
                          onNext: () => manager.send('music', 'control', {'method': 'next'}),
                          onPrev: () => manager.send('music', 'control', {'method': 'previous'}),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final String name;
  final String artist;
  final ColorScheme theme;

  const _TrackInfo({
    required this.name,
    required this.artist,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: theme.onSecondaryContainer,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          artist,
          style: TextStyle(color: theme.onSurfaceVariant, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final ColorScheme theme;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _ControlButtons({
    required this.theme,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // PREVIOUS BUTTON
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.skip_previous_outlined),
          color: theme.onSecondaryContainer,
          style: IconButton.styleFrom(
            backgroundColor: theme.secondaryContainer,
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(width: 3),

        // NEXT BUTTON
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.skip_next_outlined),
          color: theme.onSecondaryContainer,
          style: IconButton.styleFrom(
            backgroundColor: theme.secondaryContainer,
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }
}


// ---------------------------     Progress Slider     ---------------------------------------------

class MusicProgressSlider extends ConsumerStatefulWidget {
  final ColorScheme theme;
  final double duration;
  final double position;
  final String status;

  const MusicProgressSlider({
    super.key,
    required this.theme,
    required this.duration,
    required this.position,
    required this.status,
  });

  @override
  ConsumerState<MusicProgressSlider> createState() => _MusicProgressSliderState();
}

class _MusicProgressSliderState extends ConsumerState<MusicProgressSlider>
  with TickerProviderStateMixin {
  double? _dragValue;
  late double _localPosition;
  Timer? _timer;

  late AnimationController _waveController;
  late AnimationController _flattenController;

  @override
  void initState() {
    super.initState();
    _localPosition = widget.position;
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _flattenController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.status == 'Playing') {
      _flattenController.value = 1.0;
      _waveController.repeat();
    }
    _updateTimer();
  }

  @override
  void didUpdateWidget(MusicProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Track changed — reset position immediately
    if (oldWidget.duration != widget.duration) {
      _localPosition = widget.position;
    } else if (oldWidget.position != widget.position) {
      if ((_localPosition - widget.position).abs() > 2) {
        _localPosition = widget.position;
      }
    }

    if (oldWidget.status != widget.status) {
      _updateTimer();
      if (widget.status == 'Playing') {
        _waveController.repeat();
        _flattenController.forward();
      } else {
        _waveController.stop();
        _flattenController.reverse();
      }
    }
  }

  void _updateTimer() {
    _timer?.cancel();
    if (widget.status == 'Playing') {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _localPosition < widget.duration) {
          setState(() {
            _localPosition += 1.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.read(connectionManagerProvider);
    double progress = widget.duration != 0 ? _localPosition / widget.duration : 0.0;
    
    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _dragValue = (d.localPosition.dx / context.size!.width).clamp(0.0, 1.0)),
      onHorizontalDragEnd: (d) {
        if (_dragValue != null) {
          manager.send(
            "music",
            "control",
            {
              "method": 'seek',
              "position": (_dragValue! * widget.duration).toInt(),
            },
          );
          setState(() => _localPosition = _dragValue! * widget.duration);
        }
        setState(() => _dragValue = null);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _flattenController]),
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 30),
          painter: SquigglePainter(
            progress: (_dragValue ?? progress).clamp(0.0, 1.0),
            phase: _waveController.value * 2 * pi,
            amplitude: _flattenController.value * 4.0,
            color: widget.theme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    _flattenController.dispose();
    super.dispose();
  }
}


// Modify this to change the squiggly player style
class SquigglePainter extends CustomPainter {
  final double progress, phase, amplitude;
  final Color color;

  SquigglePainter({required this.progress, required this.phase, required this.amplitude, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final thumbX = size.width * progress;

    // Inactive track
    final inactivePaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    if (thumbX < size.width) {
      canvas.drawLine(Offset(thumbX, centerY), Offset(size.width, centerY), inactivePaint);
    }

    // Active track
    if (thumbX > 0) {
      const double waveLength = 30.0;
      final activePaint = Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final activePath = Path();
      activePath.moveTo(0, centerY + amplitude * sin(phase));
      for (double x = 0.8; x <= thumbX; x += 0.8) {
        final double y = centerY + amplitude * sin((x / waveLength) * 2 * pi + phase);
        activePath.lineTo(x, y);
      }
      canvas.drawPath(activePath, activePaint);
    }

    // Thumb
    canvas.drawCircle(
      Offset(thumbX, centerY),
      7.0,
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant SquigglePainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------------------------------
