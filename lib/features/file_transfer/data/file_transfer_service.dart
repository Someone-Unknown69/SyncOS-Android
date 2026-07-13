// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/network/domain/connection_config.dart';
import 'package:syncos_android/core/network/domain/i_file_transfer_channel.dart';
import 'package:syncos_android/core/storage/domain/i_file_picker.dart';
import 'package:syncos_android/core/storage/domain/models/file_structure.dart';
import 'package:syncos_android/features/file_transfer/domain/models/file_transfer_state.dart';
import 'package:syncos_android/features/file_transfer/provider/file_transfer_notifier.dart';
import '../../../core/network/domain/i_connection_manager.dart';
import '../../../core/notification/domain/i_notification_service.dart';

class FileTransferService {
  final Ref _ref;
  final IConnectionManager _connectionManager;
  final IFilePicker _filePicker;
  final IFileTransferChannel _fileTransferChannel;
  final INotificationService _notificationService;

  FileTransferNotifier get _notifier => _ref.read(fileTransferState.notifier);

  final int port = 4244;

  bool _isTransferInProgress = false;

  // Tracks checksums/files that arrive out of order relative to each
  final Map<String, String> _pendingChecksums = {};
  final Map<String, FileMetadata> _completedFiles = {};

  // Subscription to the channel's byte-progress stream so we can
  // forward updates into the notifier for the UI.
  StreamSubscription<int>? _progressSub;

  FileTransferService(
    this._ref,
    this._connectionManager,
    this._filePicker,
    this._fileTransferChannel,
    this._notificationService,
  );

  void _log(String message) {
    logDebug('File Transfer Service', message);
  }

  void _subscribeToProgress() {
    _progressSub?.cancel();
    _progressSub = _fileTransferChannel.bytesTransferredStream.listen((bytes) {
      _notifier.updateBytes(bytes);
    });
  }

  void _unsubscribeFromProgress() {
    _progressSub?.cancel();
    _progressSub = null;
  }

  /// Prompts the user to pick files, then opens the channel and streams
  /// them to the peer in the order they were picked. Checksums are
  /// computed in the background and pushed separately over the
  /// connection manager, so they never block the transfer itself.
  void initSend() async {
    final picked = await _filePicker.pickFiles();
    if (picked == null || picked.isEmpty) {
      _log('initSend aborted: no files selected');
      return;
    }

    final ip = await _getCurrentIpAddress();
    if (ip == null) {
      _log('initSend aborted: could not determine local IP address');
      return;
    }

    _notifier.startNewSession(picked.length);
    _subscribeToProgress();

    final config = TcpConfig(ip: ip, port: port);
    _connectionManager.send('file_transfer', 'open_channel', {
      ...config.toJson(),
      'fileCount': picked.length,
    });
    _log('Sent open channel command (fileCount: ${picked.length}) to peer');

    await _fileTransferChannel.openAsServer(port);
    _log('Channel open. Sending ${picked.length} file(s) in order');

    _notifier.updateStatus(TransferStatus.sending);

    for (final metadata in picked) {
      final file = File(metadata.filePath);
      if (!await file.exists()) {
        _log('Skipping missing file: ${metadata.filePath}');
        continue;
      }

      unawaited(_computeAndSendChecksum(metadata));

      _log(
        'Sending file: ${metadata.fileName} (${metadata.fileSize} bytes, id: ${metadata.fileId})',
      );
      _notifier.startNewFile(metadata);
      try {
        await _fileTransferChannel.sendFile(metadata);
        _log('Finished sending: ${metadata.fileName}');
        _notifier.addToHistory(TransferRecord(
          fileName: metadata.fileName,
          fileSize: metadata.fileSize,
          mimeType: metadata.mimeType,
          status: TransferStatus.successful,
          direction: TransferDirection.sent,
          timestamp: DateTime.now(),
        ));
      } catch (e) {
        _log('Failed to send file ${metadata.fileName}: $e');
        _notifier.addToHistory(TransferRecord(
          fileName: metadata.fileName,
          fileSize: metadata.fileSize,
          mimeType: metadata.mimeType,
          status: TransferStatus.failed,
          direction: TransferDirection.sent,
          timestamp: DateTime.now(),
        ));
      }
    }

    _unsubscribeFromProgress();
    await _fileTransferChannel.close();
    _notifier.resetToIdle();
    _log('All files sent and Channel closed');
  }

  Future<void> _computeAndSendChecksum(FileMetadata metadata) async {
    try {
      final checksum = await _calculateFileChecksum(metadata.filePath);
      _connectionManager.send('file_transfer', 'checksum', {
        'fileId': metadata.fileId,
        'checksum': checksum,
      });
      _log('Checksum computed and sent for ${metadata.fileName}: $checksum');
    } catch (e) {
      _log('Checksum computation failed for ${metadata.fileName}: $e');
    }
  }

  /// Connects to the sender and receives [expectedCount] files in order,
  /// saving each to external storage. Call this once the dispatcher
  /// receives 'open_channel' (args should contain ip, port, fileCount).
  Future<List<FileMetadata>> initReceive(Map<String, dynamic> args) async {
    if (_isTransferInProgress) {
      _log('initReceive ignored: a transfer is already in progress');
      return [];
    }
    _isTransferInProgress = true;

    try {
      final ip = args['ip'] as String;
      final port = args['port'] as int;
      final expectedCount = args['fileCount'] as int? ?? 1;

      _pendingChecksums.clear();
      _completedFiles.clear();

      _notifier.startNewSession(expectedCount);
      _subscribeToProgress();

      await _fileTransferChannel.openAsClient(ip, port);
      _log('Connected to sender. Expecting $expectedCount file(s)');

      _notifier.updateStatus(TransferStatus.receiving);

      final savePath = await _filePicker.getExternalStoragePath();
      final received = <FileMetadata>[];

      for (int i = 0; i < expectedCount; i++) {
        try {
          _log('Awaiting file ${i + 1}/$expectedCount');
          final metadata = await _fileTransferChannel.receiveFile(savePath);
          _log('Received file: ${metadata.fileName} (id: ${metadata.fileId})');

          received.add(metadata);
          _completedFiles[metadata.fileId] = metadata;
          _tryVerifyChecksum(metadata.fileId);

          _notifier.addToHistory(TransferRecord(
            fileName: metadata.fileName,
            fileSize: metadata.fileSize,
            mimeType: metadata.mimeType,
            status: TransferStatus.successful,
            direction: TransferDirection.received,
            timestamp: DateTime.now(),
          ));
        } catch (e) {
          _log('Failed to receive file ${i + 1}/$expectedCount: $e');
          break;
        }
      }

      _unsubscribeFromProgress();
      await _fileTransferChannel.close();
      _notifier.resetToIdle();
      _log(
        'Receive complete: ${received.length}/$expectedCount files received',
      );
      return received;
    } finally {
      _isTransferInProgress = false;
    }
  }

  /// Call this from wherever the connection manager delivers incoming
  /// 'file_transfer' / 'checksum' messages, so it can be matched against
  /// a file that may have already finished (or not yet arrived).
  void onChecksumMessage(Map<String, dynamic> payload) {
    final fileId = payload['fileId'] as String?;
    final checksum = payload['checksum'] as String?;
    if (fileId == null || checksum == null) return;

    _pendingChecksums[fileId] = checksum;
    _log('Checksum received for fileId $fileId: $checksum');
    _tryVerifyChecksum(fileId);
  }

  void _tryVerifyChecksum(String fileId) {
    final metadata = _completedFiles[fileId];
    final checksum = _pendingChecksums[fileId];
    if (metadata == null || checksum == null) return;

    unawaited(_verifyChecksum(metadata, checksum));
  }

  Future<void> _verifyChecksum(
    FileMetadata metadata,
    String expectedChecksum,
  ) async {
    try {
      final actual = await _calculateFileChecksum(metadata.filePath);
      final matches = actual == expectedChecksum;
      _log(
        matches
            ? 'Checksum verified OK for ${metadata.fileName}'
            : 'Checksum MISMATCH for ${metadata.fileName}: expected $expectedChecksum, got $actual',
      );
    } catch (e) {
      _log('Checksum verification failed for ${metadata.fileName}: $e');
    } finally {
      _pendingChecksums.remove(metadata.fileId);
      _completedFiles.remove(metadata.fileId);
    }
  }

  /// Call this when *we* decide to end the session early (e.g. user
  /// cancels a transfer mid-way). Notifies the peer so they clean up too.
  void dispose() {
    _notifier.updateStatus(TransferStatus.cancelling);
    _unsubscribeFromProgress();
    _fileTransferChannel.close();
    _connectionManager.send('file_transfer', 'close_channel', {});
    _notifier.resetToIdle();
  }

  void cancelCurrentFileTransfer() {
    _fileTransferChannel.cancelCurrentTransfer();
  }

  void cancelAllFileTransfer() {
    _notifier.updateStatus(TransferStatus.cancelling);
    _unsubscribeFromProgress();
    _fileTransferChannel.cancelAllTransfers();
    _notifier.resetToIdle();
  }

  void handleRemoteClose() {
    _log('Received close_channel from peer. Closing local channel only');
    _unsubscribeFromProgress();
    _fileTransferChannel.close();
    _notifier.resetToIdle();
  }

  Future<String> _calculateFileChecksum(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException(
        "File missing during hash footprint calculations",
        filePath,
      );
    }
    final fileStream = file.openRead();
    final digest = await sha256.bind(fileStream).first;
    return digest.toString();
  }

  Future<String?> _getCurrentIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        if (interface.name.contains('wlan') ||
            interface.name.contains('eth') ||
            interface.name.contains('en')) {
          for (var address in interface.addresses) {
            if (!address.isLoopback) return address.address;
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      _log(
        'Failed to determine interface adapter local network IP framework: $e',
      );
    }
    return null;
  }
}
