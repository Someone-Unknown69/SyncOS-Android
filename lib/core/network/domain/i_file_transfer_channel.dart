// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'package:syncos_android/core/storage/domain/models/file_structure.dart';

abstract class IFileTransferChannel {
  Future<void> openAsServer(int port);
  Future<void> openAsClient(String ip, int port);

  /// A stream that emits the total bytes transferred so far for the
  /// current file (send or receive direction). Resets to 0 on each new file.
  Stream<int> get bytesTransferredStream;

  /// Send a file described by [metadata] over the channel.
  /// Reads from metadata.filePath.
  Future<void> sendFile(FileMetadata metadata);

  /// Wait for an incoming file and save it into [saveDirectory].
  /// Returns the metadata with filePath updated to the saved location.
  Future<FileMetadata> receiveFile(String saveDirectory);
  Future<void> cancelCurrentTransfer();
  Future<void> cancelAllTransfers();
  Future<void> close();
}
