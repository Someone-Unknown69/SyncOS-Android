// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'models/media_info.dart';

abstract class IMediaService {
  Future<void> start();
  Future<void> stop();
  Future<void> sendControlCommand(Map<String, dynamic> args);
  Stream<MediaInfo> get mediaStream;
  void dispose();
}