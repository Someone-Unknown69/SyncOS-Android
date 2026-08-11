// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/media/domain/models/media_info.dart';
import 'package:syncos_android/features/media/provider/remote_media_provider.dart';

// ======================== PROVIDERS ========================

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
  /// Generates a Material 3 ColorScheme from an image.
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
      return ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: brightness,
      );
    }
  }
}
