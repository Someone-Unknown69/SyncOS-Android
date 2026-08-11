// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/media/domain/models/media_info.dart';
import 'package:syncos_android/features/media/provider/remote_media_provider.dart';
import 'package:syncos_android/theme/app_theme.dart';

// ======================== LOCAL PROVIDERS ========================

/// Full track state consumed by seek bar, track info, and album art.
final _trackProvider = Provider<MediaInfo>((ref) {
  return ref.watch(remoteMediaStreamProvider).value ?? MediaInfo.empty;
});

final _albumArtUriProvider = Provider<Uri?>((ref) {
  return ref.watch(_trackProvider).albumArtUri;
});

/// Generates a Material 3 ColorScheme from the current album art.
final _dynamicColorSchemeProvider = FutureProvider<ColorScheme>((ref) async {
  final artUri = ref.watch(_albumArtUriProvider);

  ImageProvider imageProvider;
  if (artUri != null && artUri.path.isNotEmpty) {
    imageProvider = FileImage(File.fromUri(artUri));
  } else {
    imageProvider = const AssetImage('assets/images/album.png');
  }

  try {
    return await ColorScheme.fromImageProvider(
      provider: imageProvider,
      brightness: Brightness.dark,
    );
  } catch (_) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    );
  }
});

final _isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(_trackProvider).status ?? false;
});

// ======================== HELPERS ========================

String _fmt(int? sec) {
  if (sec == null || sec < 0) return '0:00';
  final m = sec ~/ 60;
  final s = sec % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

// ======================== ROOT PAGE ========================

class MusicPlayerPage extends ConsumerWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorAsync = ref.watch(_dynamicColorSchemeProvider);

    final cs = colorAsync.asData?.value ?? Theme.of(context).colorScheme;
    final themedData = Theme.of(context).copyWith(colorScheme: cs);

    return Theme(
      data: themedData,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: cs.surfaceContainerLow,
        ),
        child: Scaffold(
          backgroundColor: cs.surface,
          body: const SafeArea(child: _PlayerBody()),
        ),
      ),
    );
  }
}

// ======================== PLAYER BODY ========================

class _PlayerBody extends ConsumerWidget {
  const _PlayerBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(_trackProvider);
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(cs: cs),
          const SizedBox(height: 20),
          _AlbumArt(artUri: track.albumArtUri, cs: cs),
          const SizedBox(height: 20),
          _TrackInfo(track: track, cs: cs),
          const SizedBox(height: 16),
          const _SeekBar(),
          const SizedBox(height: 16),
          _PlaybackControls(cs: cs),
        ],
      ),
    );
  }
}

// ======================== TOP BAR ========================

class _TopBar extends StatelessWidget {
  final ColorScheme cs;
  const _TopBar({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SpringButton(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.keyboard_arrow_left,
                color: cs.onSurface, size: 24),
          ),
        ),
        Text(
          'Now Playing',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(
          // TODO : Show current and available music players here
          width: 44,
          height: 44,
          child: Icon(Icons.music_note_rounded,
              color: cs.onSurfaceVariant, size: 22),
        ),
      ],
    );
  }
}

// ======================== ALBUM ART ========================

class _AlbumArt extends StatelessWidget {
  final Uri? artUri;
  final ColorScheme cs;
  const _AlbumArt({required this.artUri, required this.cs});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.borderRadius);
    return AspectRatio(
      aspectRatio: 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: artUri != null && artUri!.path.isNotEmpty
              ? Image.file(
                  File.fromUri(artUri!),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _DefaultArt(cs: cs),
                )
              : _DefaultArt(cs: cs),
        ),
      ),
    );
  }
}

class _DefaultArt extends StatelessWidget {
  final ColorScheme cs;
  const _DefaultArt({required this.cs});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.music_note_rounded,
            size: 88, color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
      ),
    );
  }
}

// ======================== TRACK INFO ========================

class _TrackInfo extends StatelessWidget {
  final MediaInfo track;
  final ColorScheme cs;
  const _TrackInfo({required this.track, required this.cs});

  @override
  Widget build(BuildContext context) {
    final title =
        (track.title?.isNotEmpty == true) ? track.title! : 'Unknown Track';
    final artist =
        (track.artist?.isNotEmpty == true) ? track.artist! : 'Unknown Artist';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ======================== SEEK BAR ========================

class _SeekBar extends ConsumerStatefulWidget {
  const _SeekBar();

  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  int _basePosition = 0;
  DateTime _baseTime = DateTime.now();
  bool _playing = false;
  int _duration = 0;

  double? _drag;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final service = ref.read(remoteMediaServiceProvider);
    final track = service.currentState;
    final lastSync = service.lastCacheTime ?? DateTime.now();

    _playing = track.status ?? false;
    _duration = track.duration ?? 0;

    int initialPos = track.position ?? 0;
    if (_playing) {
      final elapsed = DateTime.now().difference(lastSync).inSeconds;
      initialPos += elapsed;
      if (_duration > 0 && initialPos > _duration) {
        initialPos = _duration;
      }
    }
    _basePosition = initialPos;
    _baseTime = DateTime.now();

    // Request fresh state from the background service upon load
    ref.read(remoteMediaServiceProvider).requestMediaState();

    // Local UI timer to smoothly advance the seekbar position every second
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_playing && _drag == null && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _livePosition {
    if (!_playing) return _basePosition;
    final elapsed = DateTime.now().difference(_baseTime).inSeconds;
    final projected = _basePosition + elapsed;
    return _duration > 0 ? projected.clamp(0, _duration) : projected;
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(_trackProvider);
    final cs = Theme.of(context).colorScheme;

    final newPos = track.position ?? 0;
    final newDur = track.duration ?? 0;
    final newPlaying = track.status ?? false;

    // Sync local base values if a new network snapshot has been received
    if (newPos != _basePosition || newDur != _duration || newPlaying != _playing) {
      _basePosition = newPos;
      _baseTime = DateTime.now();
      _duration = newDur;
      _playing = newPlaying;
    }

    final effDur = _duration > 0 ? _duration : 1;
    final livePos = _drag != null ? (_drag! * effDur).round() : _livePosition;
    final sliderVal = (livePos / effDur).clamp(0.0, 1.0);

    return Column(
      children: [
        Semantics(
          label: 'Seek bar',
          slider: true,
          value: _fmt(livePos),
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              trackShape: const RoundedRectSliderTrackShape(),
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHighest,
              thumbColor: cs.primary,
              overlayColor: cs.primary.withValues(alpha: 0.15),
            ),
            child: ExcludeSemantics(
              child: Slider(
                value: sliderVal,
                min: 0,
                max: 1,
                onChangeStart: (_) => setState(() => _drag = sliderVal),
                onChanged: (v) => setState(() => _drag = v),
                onChangeEnd: (v) {
                  final seekTo = (v * effDur).round();
                  ref.read(remoteMediaServiceProvider).sendSeek(seekTo);
                  // Optimistically update base so the bar doesn't snap back.
                  setState(() {
                    _basePosition = seekTo;
                    _baseTime = DateTime.now();
                    _drag = null;
                  });
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(livePos),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _fmt(_duration),
                style: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================== PLAYBACK CONTROLS ========================

class _PlaybackControls extends ConsumerWidget {
  final ColorScheme cs;
  const _PlaybackControls({required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(_isPlayingProvider);
    final svc = ref.read(remoteMediaServiceProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _BlockButton(
                icon: Icons.skip_previous_rounded,
                cs: cs,
                onTap: svc.previous,
                backgroundColor: cs.surfaceContainerHigh,
                iconColor: cs.onSurface,
                height: 72,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BlockButton(
                icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                cs: cs,
                onTap: svc.playPauseToggle,
                backgroundColor: cs.primary,
                iconColor: cs.onPrimary,
                height: 72,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BlockButton(
                icon: Icons.skip_next_rounded,
                cs: cs,
                onTap: svc.next,
                backgroundColor: cs.surfaceContainerHigh,
                iconColor: cs.onSurface,
                height: 72,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _VolumeRow(cs: cs),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _BlockButton(
                icon: Icons.shuffle_rounded,
                cs: cs,
                onTap: () {
                  // TODO : Add shuffle functionality
                },

                backgroundColor: cs.primary,
                iconColor: cs.onPrimary,
                height: 56,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BlockButton(
                icon: Icons.repeat_rounded,
                cs: cs,
                onTap: () {
                  // TODO : Add repeat functionality
                },

                backgroundColor: cs.surfaceContainerHigh,
                iconColor: cs.onSurface,
                height: 56,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BlockButton(
                icon: Icons.settings_rounded,
                cs: cs,
                onTap: () {
                  // TODO : Add a settings page
                },
                backgroundColor: cs.surfaceContainerHigh,
                iconColor: cs.onSurface,
                height: 56,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BlockButton extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final double height;

  const _BlockButton({
    required this.icon,
    required this.cs,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return _SpringButton(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

// ======================== VOLUME ROW ========================

class _VolumeRow extends ConsumerStatefulWidget {
  final ColorScheme cs;
  const _VolumeRow({required this.cs});

  @override
  ConsumerState<_VolumeRow> createState() => _VolumeRowState();
}

class _VolumeRowState extends ConsumerState<_VolumeRow> {
  double _vol = 50;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_mute_rounded,
              size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              label: 'Volume',
              slider: true,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  trackShape: const RoundedRectSliderTrackShape(),
                  activeTrackColor: cs.primary,
                  inactiveTrackColor:
                      cs.onSurfaceVariant.withValues(alpha: 0.15),
                  thumbColor: cs.secondary,
                  overlayColor: cs.secondary.withValues(alpha: 0.12),
                ),
                child: ExcludeSemantics(
                  child: Slider(
                    value: _vol,
                    min: 0,
                    max: 100,
                    onChanged: (v) => setState(() => _vol = v),
                    onChangeEnd: (v) => ref
                        .read(remoteMediaServiceProvider)
                        .sendVolume(v.round()),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.volume_up_rounded,
              size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

// ======================== SPRING BUTTON ========================

class _SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringButton({required this.child, required this.onTap});

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    lowerBound: 0.92,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(scale: _ctrl, child: widget.child),
    );
  }
}
