// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/music/domain/models/media_info.dart';
import 'package:syncos_android/features/music/provider/remote_media_provider.dart';

import '../../../theme/app_theme.dart';

// ======================== PROVIDERS ========================

// Only track metadata relevant to theme (ignore position/status)
final trackMetadataProvider =
    Provider<({String? title, String? artist, Uri? albumArt})>((ref) {
      final track = ref.watch(currentTrackProvider);
      return (
        title: track.title,
        artist: track.artist,
        albumArt: track.albumArtUri,
      );
    });

final dynamicColorSchemeProvider = FutureProvider<ColorScheme>((ref) async {
  final metadata = ref.watch(trackMetadataProvider);
  final artUri = metadata.albumArt;

  ImageProvider provider;
  if (artUri != null && artUri.path.isNotEmpty) {
    provider = FileImage(File.fromUri(artUri));
  } else {
    provider = const AssetImage('assets/images/album.png');
  }

  return MusicThemeService.generate(provider, Brightness.dark);
});

final statusProvider = Provider<bool>((ref) {
  final info = ref.watch(remoteMediaStreamProvider).value ?? MediaInfo.empty;
  return info.status ?? false;
});

final currentTrackProvider = Provider<MediaInfo>((ref) {
  return ref.watch(remoteMediaStreamProvider).value ?? MediaInfo.empty;
});

// ======================== THEME SERVICE ========================

class MusicThemeService {
  /// Generates a Material 3 ColorScheme directly from an image.
  /// This uses the native Flutter algorithm to ensure harmonious tones.
  static Future<ColorScheme> generate(
    ImageProvider image,
    Brightness brightness,
  ) async {
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
  @override
  Widget build(BuildContext context) {
    final colorSchemeAsync = ref.watch(dynamicColorSchemeProvider);
    final info = ref.watch(currentTrackProvider);
    final controls = ref.watch(remoteMediaServiceProvider);
    final status = ref.watch(statusProvider);

    final colorScheme =
        colorSchemeAsync.whenData((scheme) => scheme).value ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        );

    final theme = colorScheme;
    final artUri = info.albumArtUri;
    final bool hasArt = artUri != null;

    return Theme(
      data: ThemeData(useMaterial3: true, colorScheme: theme),
      child: Builder(
        builder: (context) {
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
                  child: hasArt
                      ? SizedBox.expand(
                          child: Image.file(
                            File.fromUri(artUri),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: localTheme.surfaceContainer,
                              );
                            },
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
                          Expanded(
                            child: _TrackInfo(
                              name: info.title ?? "Nothing Playing",
                              artist: info.artist ?? "",
                              theme: localTheme,
                            ),
                          ),

                          // Play/Pause button
                          IconButton(
                            onPressed: () {
                              controls.playPauseToggle();
                            },
                            icon: Icon(
                              status
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
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                              child: MusicProgressSlider(
                                theme: theme,
                                duration: info.duration?.toDouble() ?? 0.0,
                                position: info.position?.toDouble() ?? 0.0,
                                status: status,
                              ),
                            ),
                          ),

                          _ControlButtons(
                            theme: localTheme,
                            onNext: () => controls.next(),
                            onPrev: () => controls.previous(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
  final bool status;

  const MusicProgressSlider({
    super.key,
    required this.theme,
    required this.duration,
    required this.position,
    required this.status,
  });

  @override
  ConsumerState<MusicProgressSlider> createState() =>
      _MusicProgressSliderState();
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
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _flattenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.status) {
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
      if (widget.status) {
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
    if (widget.status) {
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
    final controls = ref.watch(remoteMediaServiceProvider);
    double progress = widget.duration != 0
        ? _localPosition / widget.duration
        : 0.0;

    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(
        () => _dragValue = (d.localPosition.dx / context.size!.width).clamp(
          0.0,
          1.0,
        ),
      ),
      onHorizontalDragEnd: (d) {
        if (_dragValue != null) {
          final pos = (_dragValue! * widget.duration).toInt();
          controls.sendSeek(pos);
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

  SquigglePainter({
    required this.progress,
    required this.phase,
    required this.amplitude,
    required this.color,
  });

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
      canvas.drawLine(
        Offset(thumbX, centerY),
        Offset(size.width, centerY),
        inactivePaint,
      );
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
        final double y =
            centerY + amplitude * sin((x / waveLength) * 2 * pi + phase);
        activePath.lineTo(x, y);
      }
      canvas.drawPath(activePath, activePaint);
    }

    // Thumb
    canvas.drawCircle(
      Offset(thumbX, centerY),
      7.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant SquigglePainter oldDelegate) => true;
}
