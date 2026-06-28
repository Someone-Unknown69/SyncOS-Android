// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/media/data/android_media_info.dart';
import 'package:syncos_android/core/media/domain/i_local_media_info.dart';
import 'package:syncos_android/features/media/domain/models/media_info.dart';

final localMediaInfoProvider = Provider<ILocalMediaInfo>((ref) {
  return AndroidMediaInfo();
});

final mediaMetadataStreamProvider = StreamProvider<MediaInfo>((ref) async* {
  final streamProvider = ref.watch(localMediaInfoProvider);
  await streamProvider.start();
  yield* streamProvider.metadataStream;
});
