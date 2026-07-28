import 'package:syncos_android/core/storage/domain/models/file_structure.dart';

enum TransferStatus {
  idle,
  initializing,
  sending,
  receiving,
  calculatingChecksum,
  cancelling,
  verifying,
  failed,
  successful,
}

enum TransferDirection { sent, received }

class TransferRecord {
  final String fileName;
  final int fileSize;
  final String mimeType;
  final TransferStatus status;
  final TransferDirection direction;
  final DateTime timestamp;

  const TransferRecord({
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.status,
    required this.direction,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'status': status.name,
        'direction': direction.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      fileName: json['fileName'] as String? ?? 'Unknown',
      fileSize: json['fileSize'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.successful,
      ),
      direction: TransferDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => TransferDirection.received,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferRecord &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          fileSize == other.fileSize &&
          mimeType == other.mimeType &&
          status == other.status &&
          direction == other.direction &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      fileName.hashCode ^
      fileSize.hashCode ^
      mimeType.hashCode ^
      status.hashCode ^
      direction.hashCode ^
      timestamp.hashCode;
}

class FileTransferState {
  final TransferStatus status;
  final FileMetadata? currentFile;
  final int totalFiles;
  final int currentFileIndex;
  final int bytesTransferred;
  final List<TransferRecord> history;

  FileTransferState({
    required this.status,
    this.currentFile,
    this.totalFiles = 0,
    this.currentFileIndex = 0,
    this.bytesTransferred = 0,
    this.history = const [],
  });

  FileTransferState copyWith({
    TransferStatus? status,
    FileMetadata? currentFile,
    int? totalFiles,
    int? currentFileIndex,
    int? bytesTransferred,
    List<TransferRecord>? history,
  }) {
    return FileTransferState(
      status: status ?? this.status,
      currentFile: currentFile ?? this.currentFile,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      history: history ?? this.history,
    );
  }
}
