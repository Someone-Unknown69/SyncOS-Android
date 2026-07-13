// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'dart:convert';

// generic file metadata to send over FTP
typedef FileMetadata = ({
  String fileId,   // ID to track specific transfer session
  String filePath,     // Absolute path on the sender's device
  String fileName,     // Name of the file with extension
  int fileSize,        // Total file size in bytes
  String mimeType,     // Useful for the receiver to handle file types correctly
  String? checksum,
});

extension FileMetadataExtension on FileMetadata {
  FileMetadata copyWith({String? checksum}) {
    return (
      fileId: fileId,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      checksum: checksum ?? this.checksum,
    );
  }

  /// Converts the metadata record into a standard Map structure.
  Map<String, dynamic> toMap() {
    return {
      'fileId': fileId,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'checksum': checksum,
    };
  }

  /// Serializes the metadata to JSON string for network transmission.
  String toJson() => jsonEncode(toMap());
}

abstract final class FileMetadataParser {
  
  /// Rebuilds the FileMetadata record from a Map.
  static FileMetadata fromMap(Map<String, dynamic> map) {
    return (
      fileId: map['fileId'] as String,
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      fileSize: map['fileSize'] as int,
      mimeType: map['mimeType'] as String,
      checksum: map['checksum'] as String?,
    );
  }

  /// Rebuilds the metadata record directly from an incoming network JSON string.
  static FileMetadata fromJson(String source) {
    return fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
