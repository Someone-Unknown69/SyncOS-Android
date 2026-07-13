// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:syncos_android/core/storage/domain/models/file_structure.dart';

abstract class IFilePicker {
  Future<List<FileMetadata>?> pickFiles();
  Future<String> getExternalStoragePath();
}
