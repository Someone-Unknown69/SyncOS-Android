import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'socket_client.dart';

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
  final int position;
  final int duration;
  final String status;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final String? albumArtBase64;
  final SocketClient? client;

  const MusicPlayerWidget({
    super.key,
    required this.imagePath,
    required this.trackName,
    required this.artistName,
    required this.position,
    required this.duration,
    required this.status,
    required this.onPlay,
    required this.onNext,
    required this.onPrev,
    required this.albumArtBase64,
    this.client,
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
    ImageProvider provider;
    if (widget.imagePath != 'N/A' && widget.imagePath.length > 50) {
      try {
        Uint8List bytes = base64Decode(widget.imagePath);
        try {
          bytes = Uint8List.fromList(gzip.decode(bytes));
        } catch (_) {} // ignore if not gzipped
        provider = MemoryImage(bytes);
      } catch (e) {
        provider = const AssetImage('assets/images/album2.png'); // Fallback asset
      }
    } else {
      provider = const AssetImage('assets/images/album2.png');
    }

    final scheme = await MusicThemeService.generate(
      provider,
      Brightness.dark,
    );
    if (mounted) {
      setState(() => _dynamicScheme = scheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (widget.imagePath != 'N/A' && widget.imagePath.length > 50) {
      try {
        imageBytes = base64Decode(widget.imagePath);
        try {
          imageBytes = Uint8List.fromList(gzip.decode(imageBytes));
        } catch (_) {}
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
      }
    }

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
              Positioned.fill(
                child: imageBytes != null
                  ? SizedBox.expand(
                      child: Image.memory(
                        imageBytes, 
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  : Container(color: localTheme.surfaceContainer), // Fallback if no art
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
                        Expanded(child: 
                          _TrackInfo(
                            name: widget.trackName,
                            artist: widget.artistName,
                            theme: localTheme,
                          ),
                        ),

                          // Play button
                        IconButton(
                          onPressed: widget.onPlay,
                          icon: Icon(
                            widget.status == 'Playing' ? Icons.pause_outlined : Icons.play_arrow_outlined,
                            size: 25
                          ),
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
                            duration: widget.duration.toDouble(),
                            position: widget.position.toDouble(),
                            status: widget.status,
                            client: widget.client,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: theme.onSecondaryContainer,
            fontSize: 14,
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


class MusicProgressSlider extends StatefulWidget {
  final ColorScheme theme;
  final double duration;
  final double position;
  final String status;
  final SocketClient? client;

  const MusicProgressSlider({
    super.key,
    required this.theme,
    required this.duration,
    required this.position,
    required this.status,
    this.client,
  });

  @override
  State<MusicProgressSlider> createState() => _MusicProgressSliderState();
}

class _MusicProgressSliderState extends State<MusicProgressSlider> {
  double? _dragValue;
  late double _localPosition;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _localPosition = widget.position;
    _updateTimer();
  }

  @override
  void didUpdateWidget(MusicProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      if ((_localPosition - widget.position).abs() > 2) {
        _localPosition = widget.position;
      }
    }
    if (oldWidget.status != widget.status) {
      _updateTimer();
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;
    if(_localPosition != 0 && widget.duration != 0) {
      progress = _localPosition / widget.duration;
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
        activeTrackColor: Theme.of(context).colorScheme.onSecondaryContainer,
        inactiveTrackColor: Theme.of(context).colorScheme.onSecondary,
        thumbColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      child: Slider(
        value: (_dragValue ?? progress).clamp(0.0, 1.0),
        min: 0.0,
        max: 1.0,
        onChanged: (newValue) {
          setState(() => _dragValue = newValue);
        },
        onChangeEnd: (newValue) {
          if (widget.client != null && widget.duration > 0) {
            final targetSeconds = (newValue * widget.duration).toInt();
            widget.client!.sendJson({
              "op": "seek",
              "args": {"position": targetSeconds}
            });
            setState(() {
              _localPosition = targetSeconds.toDouble();
              _dragValue = null;
            });
          } else {
            setState(() => _dragValue = null);
          }
        },
      ),
    );
  }
}