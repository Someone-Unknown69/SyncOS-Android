import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncos_android/core/storage/domain/models/file_structure.dart';
import 'package:syncos_android/core/storage/provider/storage_service_provider.dart';
import 'package:syncos_android/features/file_transfer/domain/models/file_transfer_state.dart';

part 'file_transfer_notifier.g.dart';

@Riverpod(name: 'fileTransferState')
class FileTransferNotifier extends _$FileTransferNotifier {
  @override
  FileTransferState build() {
    _loadHistory();
    return FileTransferState(status: TransferStatus.idle);
  }

  Future<void> _loadHistory() async {
    final storage = ref.read(storageServiceProvider);
    final savedHistory = await storage.getFileTransferHistory();
    if (savedHistory.isNotEmpty) {
      state = state.copyWith(history: savedHistory);
    }
  }

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
    final storage = ref.read(storageServiceProvider);
    storage.addTransferRecord(record);
  }

  void clearHistory() {
    state = state.copyWith(history: const []);
    final storage = ref.read(storageServiceProvider);
    storage.clearFileTransferHistory();
  }

  void resetToIdle() {
    state = FileTransferState(
      status: TransferStatus.idle,
      history: state.history,
    );
  }
}
