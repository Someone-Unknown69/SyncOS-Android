// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:syncos_android/features/media/domain/models/media_info.dart';

abstract class ILocalMediaInfo {
  Stream<MediaInfo> get metadataStream;
  Future<void> start();
  void stop();
  void dispose();
  void control(Map<String, dynamic> args);
}
