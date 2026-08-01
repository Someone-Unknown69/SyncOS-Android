// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/media/provider/remote_media_provider.dart';
import 'package:syncos_android/features/media/ui/music_player.dart';
import 'package:syncos_android/theme/app_theme.dart';
import 'package:syncos_android/features/device_info/provider/remote_device_info_state.dart';
import 'package:syncos_android/core/config/app_routes.dart';
import 'package:syncos_android/core/config/app_router.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage> {
  double _volume = 0.5;
  bool _isShuffle = false;
  bool _isRepeat = false;

  @override
  Widget build(BuildContext context) {
    final colorSchemeAsync = ref.watch(dynamicColorSchemeProvider);
    final info = ref.watch(currentTrackProvider);
    final controls = ref.watch(remoteMediaServiceProvider);
    final status = ref.watch(statusProvider);
    final deviceState = ref.watch(deviceInfoProvider);

    final colorScheme =
        colorSchemeAsync.whenData((s) => s).value ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        );

    final artUri = info.albumArtUri;
    final bool hasArt = artUri != null;

    // Primary tinted colors derived from album art
    final dominantColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;

    // The bottom panel gradient: from dominant color (dark tinted) fading to surface
    final panelTopColor = Color.lerp(dominantColor, Colors.black, 0.45)!;
    final panelBottomColor = Color.lerp(surfaceColor, Colors.black, 0.6)!;

    // On-content colors — adapt to the album palette
    final onContent = colorScheme.onSurface;
    final onContentMuted = onContent.withValues(alpha: 0.55);
    final accentColor = colorScheme.primary;

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme.copyWith(brightness: Brightness.dark),
      ),
      child: Scaffold(
        backgroundColor: panelBottomColor,
        body: Stack(
          children: [
            // ── Full-screen background: album art top + gradient panel bottom ──
            Column(
              children: [
                // Top: album art (60% of screen)
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: hasArt
                            ? Image.file(
                                File.fromUri(artUri),
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (ctx, e, s) => Container(
                                  color: colorScheme.surfaceContainer,
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    size: 100,
                                    color: accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceContainer,
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 100,
                                  color: accentColor.withValues(alpha: 0.3),
                                ),
                              ),
                      ),
                      // Gradient fade from image into the tinted panel below
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 220,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                panelTopColor.withValues(alpha: 0.3),
                                panelTopColor,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom: control panel — gradient tinted with dominant album color
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [panelTopColor, panelBottomColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Top Bar: Gradient fade with Back Button and Now Playing Text ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 40, // Extend gradient below the buttons
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SizedBox(
                  height: 56, // Standard Toolbar Height
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: onContent,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'NOW PLAYING',
                          style: TextStyle(
                            color: onContentMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Main overlay content pinned to the bottom ──
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.padding * 1.5,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(flex: 7),

                      // Song title / artist / three-dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info.title ?? 'Nothing Playing',
                                  style: TextStyle(
                                    color: onContent,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  info.artist ?? '',
                                  style: TextStyle(
                                    color: onContentMuted,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => Container(
                                  decoration: BoxDecoration(
                                    color: panelBottomColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Media Player Info',
                                        style: TextStyle(
                                          color: onContent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Active Player: ${info.album ?? 'Unknown'}',
                                        style: TextStyle(
                                          color: onContentMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Status: ${status == true ? 'Playing' : 'Paused'}',
                                        style: TextStyle(
                                          color: onContentMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: onContent,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Wiggly progress slider with updating labels
                      WigglyProgressSlider(
                        duration: info.duration?.toDouble() ?? 0.0,
                        position: info.position?.toDouble() ?? 0.0,
                        isPlaying: status,
                        color: accentColor,
                        labelColor: onContentMuted,
                        onSeek: (pos) => controls.sendSeek(pos),
                      ),

                      const SizedBox(height: 12),

                      // Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: _isShuffle ? accentColor : onContentMuted,
                              size: 26,
                            ),
                            onPressed: () =>
                                setState(() => _isShuffle = !_isShuffle),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.fast_rewind_rounded,
                              color: onContent,
                              size: 46,
                            ),
                            onPressed: () => controls.previous(),
                          ),
                          GestureDetector(
                            onTap: () => controls.playPauseToggle(),
                            child: Icon(
                              status
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 68,
                              color: onContent,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.fast_forward_rounded,
                              color: onContent,
                              size: 46,
                            ),
                            onPressed: () => controls.next(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.repeat_rounded,
                              color: _isRepeat ? accentColor : onContentMuted,
                              size: 26,
                            ),
                            onPressed: () =>
                                setState(() => _isRepeat = !_isRepeat),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Volume controls
                      Row(
                        children: [
                          Icon(
                            Icons.volume_mute_rounded,
                            color: onContentMuted,
                            size: 20,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                activeTrackColor: accentColor,
                                inactiveTrackColor: accentColor.withValues(
                                  alpha: 0.25,
                                ),
                                thumbColor: accentColor,
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                              ),
                              child: Slider(
                                value: _volume,
                                onChanged: (val) {
                                  setState(() => _volume = val);
                                  controls.sendVolume((val * 100).toInt());
                                },
                              ),
                            ),
                          ),
                          Icon(
                            Icons.volume_up_rounded,
                            color: onContentMuted,
                            size: 20,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Output device name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.headphones_rounded,
                            color: onContentMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            deviceState.name,
                            style: TextStyle(
                              color: onContentMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bottom actions (Cast, Timer, Settings)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PillButton(
                                icon: Icons.cast_connected_rounded,
                                color: accentColor,
                                onContent: onContent,
                              ),
                              const SizedBox(width: 12),
                              _PillButton(
                                icon: Icons.timer_rounded,
                                color: accentColor,
                                onContent: onContent,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.settings_rounded,
                              color: onContentMuted,
                              size: 24,
                            ),
                            onPressed: () => AppRouter.pushRoute(
                              context,
                              AppRoutes.connectionDetails,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small themed pill-shaped icon button for the bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color onContent;

  const _PillButton({
    required this.icon,
    required this.color,
    required this.onContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Icon(icon, color: onContent, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wiggly Progress Slider — squiggle painter + self-ticking time labels
// ─────────────────────────────────────────────────────────────────────────────

class WigglyProgressSlider extends StatefulWidget {
  final double duration;
  final double position;
  final bool isPlaying;
  final Color color;
  final Color labelColor;
  final Function(int) onSeek;

  const WigglyProgressSlider({
    super.key,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.color,
    required this.labelColor,
    required this.onSeek,
  });

  @override
  State<WigglyProgressSlider> createState() => _WigglyProgressSliderState();
}

class _WigglyProgressSliderState extends State<WigglyProgressSlider>
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
    if (widget.isPlaying) {
      _flattenController.value = 1.0;
      _waveController.repeat();
    }
    _updateTimer();
  }

  @override
  void didUpdateWidget(WigglyProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _localPosition = widget.position;
    } else if (oldWidget.position != widget.position) {
      if ((_localPosition - widget.position).abs() > 2) {
        _localPosition = widget.position;
      }
    }

    if (oldWidget.isPlaying != widget.isPlaying) {
      _updateTimer();
      if (widget.isPlaying) {
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
    if (widget.isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _localPosition < widget.duration) {
          setState(() => _localPosition += 1.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    _flattenController.dispose();
    super.dispose();
  }

  String _fmt(double secs) {
    final s = secs.toInt();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration != 0
        ? _localPosition / widget.duration
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (d) => setState(
            () => _dragValue = (d.localPosition.dx / context.size!.width).clamp(
              0.0,
              1.0,
            ),
          ),
          onHorizontalDragEnd: (d) {
            if (_dragValue != null) {
              final pos = (_dragValue! * widget.duration).toInt();
              widget.onSeek(pos);
              setState(() => _localPosition = _dragValue! * widget.duration);
            }
            setState(() => _dragValue = null);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_waveController, _flattenController]),
            builder: (context, _) => CustomPaint(
              size: const Size(double.infinity, 24),
              painter: SquigglePainter(
                progress: (_dragValue ?? progress).clamp(0.0, 1.0),
                phase: _waveController.value * 2 * math.pi,
                amplitude: _flattenController.value * 4.0,
                color: widget.color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fmt(
                _dragValue != null
                    ? _dragValue! * widget.duration
                    : _localPosition,
              ),
              style: TextStyle(
                color: widget.labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _fmt(widget.duration),
              style: TextStyle(
                color: widget.labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
