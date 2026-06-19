// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'package:syncos_android/features/music/domain/models/media_info.dart';

abstract class IRemoteMediaState {
  Stream<MediaInfo> get mediaUpdates;
  MediaInfo get currentState;
}
