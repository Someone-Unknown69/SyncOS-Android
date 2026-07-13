// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/storage/data/android_file_picker.dart';
import 'package:syncos_android/core/storage/domain/i_file_picker.dart';

final filePickerProvider = Provider<IFilePicker>((ref) {
  return AndroidFilePicker();
});
