import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncos_android/core/storage/domain/models/file_structure.dart';
import 'package:syncos_android/features/file_transfer/domain/models/file_transfer_state.dart';

part 'file_transfer_notifier.g.dart';

@Riverpod(name: 'fileTransferState')
class FileTransferNotifier extends _$FileTransferNotifier {
  @override
  FileTransferState build() => FileTransferState(status: TransferStatus.idle);

  void startNewSession(int totalFiles) {
    state = state.copyWith(
      totalFiles: totalFiles,
      currentFileIndex: 0,
      bytesTransferred: 0,
      status: TransferStatus.initializing,
    );
  }

  void startNewFile(FileMetadata metadata) {
    state = state.copyWith(
      currentFile: metadata,
      currentFileIndex: state.currentFileIndex + 1,
      bytesTransferred: 0,
    );
  }

  void updateBytes(int bytes) {
    state = state.copyWith(bytesTransferred: bytes);
  }

  void updateStatus(TransferStatus newStatus) {
    state = state.copyWith(status: newStatus);
  }

  void addToHistory(TransferRecord record) {
    state = state.copyWith(history: [record, ...state.history]);
  }

  void clearHistory() {
    state = state.copyWith(history: const []);
  }

  void removeHistoryRecord(int index) {
    if (index >= 0 && index < state.history.length) {
      final newList = List<TransferRecord>.from(state.history)..removeAt(index);
      state = state.copyWith(history: newList);
    }
  }

  void resetToIdle() {
    state = FileTransferState(
      status: TransferStatus.idle,
      history: state.history,
    );
  }
}
