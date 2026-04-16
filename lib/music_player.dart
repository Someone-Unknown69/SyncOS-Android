import 'dart:ui';
import 'package:flutter/material.dart';

// -----------------------------      Get metadata from player      ----------------------------------

// await NowPlaying.instance.start();




// -------------------------------      Dashboard Widget     ---------------------------------------

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

class MusicPlayerWidget extends StatefulWidget {
  final String imagePath;
  final String trackName;
  final String artistName;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const MusicPlayerWidget({
    super.key,
    required this.imagePath,
    required this.trackName,
    required this.artistName,
    required this.onPlay,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  ColorScheme? _dynamicScheme;

  @override
  void initState() {
    super.initState();
    _updateTheme();
  }

  @override
  void didUpdateWidget(MusicPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _updateTheme();
    }
  }

  Future<void> _updateTheme() async {
    final scheme = await MusicThemeService.generate(
      AssetImage(widget.imagePath),
      Brightness.dark,
    );
    if (mounted) {
      setState(() => _dynamicScheme = scheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _dynamicScheme ?? Theme.of(context).colorScheme;

    return Theme(
      data: ThemeData(useMaterial3: true, colorScheme: theme),
      child: Builder(builder: (context) {
        final localTheme = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.all(5),
          height: 200,
          clipBehavior: Clip.antiAlias,

          decoration: BoxDecoration(
            color: localTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          
          child: Stack(
            children: [
              // Blurred Background
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Image.asset(widget.imagePath, fit: BoxFit.cover),
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        localTheme.surface.withValues(alpha: 1.0),
                        localTheme.scrim.withValues(alpha: -0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Layout Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          _TrackInfo(
                            name: widget.trackName,
                            artist: widget.artistName,
                            theme: localTheme,
                          ),

                          // Play button
                          IconButton(
                          onPressed: widget.onPlay,
                          icon: const Icon(Icons.play_arrow_outlined, size: 25),
                          color: theme.primaryContainer,
                          style: IconButton.styleFrom(
                            backgroundColor: theme.onPrimaryContainer,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(15),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: 
                          MusicProgressSlider(
                            theme: theme,
                          ),
                        ),
                        
                        _ControlButtons(
                          theme: localTheme,
                          onNext: widget.onNext,
                          onPrev: widget.onPrev,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: theme.onSecondaryContainer,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              artist,
              style: TextStyle(color: theme.onSurfaceVariant, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

class MusicProgressSlider extends StatefulWidget {
  final ColorScheme theme;

  const MusicProgressSlider({
    super.key,
    required this.theme
  });

  @override
  State<MusicProgressSlider> createState() => _MusicProgressSliderState();
}

class _MusicProgressSliderState extends State<MusicProgressSlider> {
  double _value = 50.0;
  final double _max = 100; // 100 % of the time

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 5.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
        activeTrackColor: Theme.of(context).colorScheme.onSecondaryContainer,
        inactiveTrackColor: Theme.of(context).colorScheme.onSecondary,
        thumbColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      child: Slider(
        value: _value,
        min: 0.0,
        max: _max,
        onChanged: (newValue) {
          setState(() => _value = newValue);
        },
      ),
    );
  }
}