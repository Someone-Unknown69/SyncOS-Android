// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:external_path/external_path.dart';
import 'package:syncos_android/core/storage/domain/i_file_picker.dart';
import 'package:syncos_android/core/storage/domain/models/file_structure.dart';

class AndroidFilePicker implements IFilePicker {
  final _random = Random();
  final chunkSize = 65536; // 64 KB

  @override
  Future<List<FileMetadata>?> pickFiles() async {
    // Allows multi-selection by default
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return null;

    final List<FileMetadata> metadataList = [];

    for (final pickedFile in result.files) {
      final path = pickedFile.path;
      if (path == null) continue;

      final FileMetadata meta = (
        fileId: _generateId(),
        filePath: path,
        fileName: pickedFile.name,
        fileSize: pickedFile.size,
        mimeType: pickedFile.extension ?? 'application/octet-stream',
        checksum: null,
      );

      metadataList.add(meta);
    }

    return metadataList.isNotEmpty ? metadataList : null;
  }

  @override
  Future<String> getExternalStoragePath() async {
    return await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOWNLOAD,
    );
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNonce = _random.nextInt(100000);
    return 'tx-$timestamp-$randomNonce';
  }
}

