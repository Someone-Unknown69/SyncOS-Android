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
