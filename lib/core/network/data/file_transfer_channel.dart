// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/core/network/domain/i_file_transfer_channel.dart';
import 'package:syncos_android/core/storage/domain/models/file_structure.dart';

// Frame types for the binary wire protocol
const int _typeJson = 0x01;
const int _typeFileStart = 0x02;
const int _typeFileChunk = 0x03;
const int _typeFileEnd = 0x04;
const int _typeCancelTransfer = 0x05;
const int _typeCancelAll = 0x06;

// the framing is below for referance  : 5 bytes header
//
//  0               1                 2                 3                 4                 5
//  0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8
// |----------------------------------------------------------------------------------------|
// | Type (1 Byte) |             Length (4 Bytes, Big Endian)                               |
// |----------------------------------------------------------------------------------------|
// |                                        Payload                                         |
// |                                     (Length bytes)                                     |
// |----------------------------------------------------------------------------------------|

class FileTransferChannel implements IFileTransferChannel {
  ServerSocket? _serverSocket;
  Socket? _socket;
  StreamSubscription? _socketSubscription;

  final Queue<Map<String, dynamic>> _messageQueue = Queue();
  final BytesBuilder _recvBuffer = BytesBuilder(copy: false);

  // Incoming file state only ever touched synchronously inside
  // _handleFrame, never read/written across an await boundary , this check is important so a
  // file_start for file N+1 can never race with file N's async cleanup
  IOSink? _incomingFileSink;
  FileMetadata? _incomingMetadata;
  int _incomingBytesWritten = 0;
  String? _currentSaveDirectory;

  // Queue of pending receiveFile() calls, resolved strictly in the
  // order files finish arriving on the wire (FIFO)
  final Queue<Completer<FileMetadata>> _receiveQueue = Queue();

  // Serializes the async "close sink + complete queue entry" work for
  // each finished file so completions always resolve in the same order
  // file_end frames were processed ,even if one file's sink.close()
  // takes longer than another's (real disk I/O has no ordering
  // guarantee between two independent async calls)
  Future<void> _finishChain = Future.value();

  // Guards against overlapping/duplicate close() calls, which can throw
  // "StreamSink is bound to a stream" if a socket is closed twice
  // concurrently (e.g. from a close_channel ping-pong loop)
  bool _isClosed = false;

  // Ensures only one peer is ever accepted per openAsServer() call
  // prevents a duplicate/retried open_channel command from opening a
  // second connection
  bool _peerAccepted = false;

  // Broadcast stream emitting cumulative bytes for the current file.
  // Resets to 0 at each file_start / sendFile call.
  StreamController<int> _bytesController =
      StreamController<int>.broadcast();

  @override
  Stream<int> get bytesTransferredStream => _bytesController.stream;

  void _log(String message) => logDebug('FileTransferChannel', message);

  @override
  Future<void> openAsServer(int port) async {
    if (_serverSocket != null) {
      _log('Server socket already bound, closing before rebinding');
      await _serverSocket!.close();
      _serverSocket = null;
    }

    _isClosed = false;
    _peerAccepted = false;
    _finishChain = Future.value();

    _log('Binding server socket on port: $port');
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _log('Server socket bound. Waiting for peer connection');

    final connectionCompleter = Completer<void>();

    _serverSocket!.listen(
      (socket) async {
        if (_peerAccepted) {
          // A duplicate/late connection attempt reject it
          _log(
            'Rejecting extra connection from ${socket.remoteAddress.address}:${socket.remotePort} peer already accepted',
          );
          await socket.close();
          return;
        }
        _peerAccepted = true;

        _log(
          'Peer connected: ${socket.remoteAddress.address}:${socket.remotePort}',
        );
        socket.setOption(SocketOption.tcpNoDelay, true);
        _socket = socket;
        _listen(socket);

        // Stop listening for further connections entirely we only ever
        // want exactly one peer per open channel.
        await _serverSocket?.close();

        if (!connectionCompleter.isCompleted) {
          connectionCompleter.complete();
        }
      },
      onError: (error) {
        _log('Server socket error: $error');
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError(error);
        }
      },
    );

    await connectionCompleter.future;
    _log('openAsServer complete peer is connected');
  }

  @override
  Future<void> openAsClient(String ip, int port) async {
    const int maxAttempts = 5;
    const Duration retryDelay = Duration(seconds: 1);

    _isClosed = false;
    _finishChain = Future.value();

    // Ab isme bhi attempt lagege
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _log('Connecting to $ip:$port (attempt $attempt/$maxAttempts)');
        _socket = await Socket.connect(ip, port);
        _socket!.setOption(SocketOption.tcpNoDelay, true);
        _log('Connected to $ip:$port.');
        _listen(_socket!);
        return;
      } catch (e) {
        _log('Connection attempt $attempt failed: $e');
        if (attempt == maxAttempts) {
          _log('All $maxAttempts connection attempts failed. Giving up');
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }
  }

  void _listen(Socket socket) {
    _socketSubscription = socket.listen(
      (Uint8List data) {
        _recvBuffer.add(data);
        _drainFrames();
      },
      onDone: () {
        _log('Socket closed by remote.');
        _socketSubscription?.cancel();
      },
      onError: (e) {
        _log('Socket error: $e');
        _socketSubscription?.cancel();
      },
    );
  }

  // Parses [type(1)][length(4, big-endian)][payload] frames.
  // Only the leftover tail (< one frame) gets re-copied each call,
  // so cost stays bounded regardless of total transfer size
  void _drainFrames() {
    final Uint8List buffer = _recvBuffer.toBytes();
    int offset = 0;

    while (buffer.length - offset >= 5) {
      final type = buffer[offset];
      final length = ByteData.sublistView(
        buffer,
        offset + 1,
        offset + 5,
      ).getUint32(0, Endian.big);
      final frameTotal = 5 + length;

      if (buffer.length - offset < frameTotal) break; // wait for more bytes to

      final payload = buffer.sublist(offset + 5, offset + 5 + length);
      _handleFrame(type, payload);
      offset += frameTotal;
    }

    _recvBuffer.clear();
    if (offset < buffer.length) {
      _recvBuffer.add(buffer.sublist(offset));
    }
  }

  void _handleFrame(int type, Uint8List payload) {
    switch (type) {
      case _typeJson:
        try {
          final decoded =
              jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          _messageQueue.add(decoded);
          _log('Message received and queued: $decoded');
        } catch (e) {
          _log('Failed to decode JSON payload: $e');
        }
        break;

      case _typeFileStart:
        final incomingMeta = FileMetadataParser.fromJson(utf8.decode(payload));
        final savePath =
            '${_currentSaveDirectory ?? '.'}/${incomingMeta.fileName}';
        _incomingMetadata = _rebuildWithSavePath(incomingMeta, savePath);
        _incomingBytesWritten = 0;
        _incomingFileSink = File(savePath).openWrite();
        // Reset progress for the new file
        if (!_bytesController.isClosed) _bytesController.add(0);
        _log(
          'Incoming file started: ${incomingMeta.fileName} (${incomingMeta.fileSize} bytes expected, id: ${incomingMeta.fileId})',
        );
        break;

      case _typeFileChunk:
        if (_incomingFileSink == null) {
          _log('Received file_chunk with no active transfer, Ignoring');
          return;
        }
        _incomingFileSink!.add(payload);
        _incomingBytesWritten += payload.length;
        if (!_bytesController.isClosed) {
          _bytesController.add(_incomingBytesWritten);
        }
        break;

      case _typeFileEnd:
        // Capture and clear synchronously, BEFORE any await, so a
        // file_start frame processed later in this same drain loop can
        // never race with this file's cleanup.
        final finishedSink = _incomingFileSink;
        final finishedMetadata = _incomingMetadata;
        final finishedBytes = _incomingBytesWritten;
        _incomingFileSink = null;
        _incomingMetadata = null;
        _log(
          'Incoming file complete: ${finishedMetadata?.fileName} ($finishedBytes bytes written)',
        );

        // Chain onto the previous finish task instead of firing
        // independently ,guarantees completions resolve in the same
        // order file_end frames were received, regardless of how long
        // any individual sink.close() takes.
        // it's really important to not await here, altough this method is already synchronous but still for info
        _finishChain = _finishChain.then(
          (_) => _finishIncomingFile(finishedSink, finishedMetadata),
        );
        break;
      case _typeCancelTransfer:
        // cancels current transfer and clears up partially written file
        _log('Transfer Cancelled requested from peer');
        _finishChain = _finishChain.then((_) => _cleanupIncompleteFile());
        break;
      case _typeCancelAll:
        _log('Remote peer initiated a batch cancellation');
        _finishChain = _finishChain.then((_) => _wipeEntireQueue());
        break;
      default:
        _log('Unknown frame type: $type');
    }
  }

  @override
  Future<void> cancelCurrentTransfer() async {
    _log('Initiating transfer cancellation');

    try {
      _writeFrame(_typeCancelTransfer, const []);
      await _socket?.flush();
    } catch (e) {
      _log('Could not send cancel frame (socket might already be dead): $e');
    }

    await _cleanupIncompleteFile();
  }

  Future<void> _cleanupIncompleteFile() async {
    // Capture values synchronously inside the event framework
    final localSink = _incomingFileSink;
    final localMetadata = _incomingMetadata;

    _incomingFileSink = null;
    _incomingMetadata = null;
    _incomingBytesWritten = 0;

    if (localSink != null) {
      try {
        await localSink.close();
        if (localMetadata != null) {
          final partialFile = File(localMetadata.filePath);
          if (await partialFile.exists()) {
            await partialFile.delete(); // Erase the corrupt chunk from storage
            _log(
              'Cleaned up partial file footprint: ${localMetadata.fileName}',
            );
          }
        }
      } catch (e) {
        _log('Error during file cleanup execution: $e');
      }
    }

    // Pop the top completer from the queue and notify the app layer it failed
    if (_receiveQueue.isNotEmpty) {
      final completer = _receiveQueue.removeFirst();
      if (!completer.isCompleted) {
        completer.completeError(Exception('Transfer was actively canceled.'));
      }
    }
  }

  @override
  Future<void> cancelAllTransfers() async {
    _log('Initiating global Cancel All sequence');

    try {
      _writeFrame(_typeCancelAll, const []);
      await _socket?.flush();
    } catch (e) {
      _log('Could not send cancel_all frame: $e');
    }

    await _wipeEntireQueue();
  }

  Future<void> _wipeEntireQueue() async {
    final localSink = _incomingFileSink;
    final localMetadata = _incomingMetadata;

    _incomingFileSink = null;
    _incomingMetadata = null;
    _incomingBytesWritten = 0;

    // Clean up the current active file on disk
    if (localSink != null) {
      try {
        await localSink.close();
        if (localMetadata != null) {
          final partialFile = File(localMetadata.filePath);
          if (await partialFile.exists()) {
            await partialFile.delete();
            _log('Wiped partial file from batch: ${localMetadata.fileName}');
          }
        }
      } catch (e) {
        _log('Error cleaning up active file during batch cancel: $e');
      }
    }

    _log(
      'Flushing ${_receiveQueue.length} pending files from the receive queue',
    );

    for (final completer in _receiveQueue) {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('All pending transfers were canceled by the user'),
        );
      }
    }
    _receiveQueue.clear();
  }

  // filePath in the sender's metadata points to their local file;
  // on the receiving side we swap it for the local save path before
  // handing the metadata back to the caller.
  FileMetadata _rebuildWithSavePath(FileMetadata original, String savePath) {
    return (
      fileId: original.fileId,
      filePath: savePath,
      fileName: original.fileName,
      fileSize: original.fileSize,
      mimeType: original.mimeType,
      checksum: original.checksum,
    );
  }

  Future<void> _finishIncomingFile(IOSink? sink, FileMetadata? metadata) async {
    await sink?.close();
    if (metadata != null && _receiveQueue.isNotEmpty) {
      final completer = _receiveQueue.removeFirst();
      if (!completer.isCompleted) {
        completer.complete(metadata);
      }
    }
  }

  void _writeFrame(int type, List<int> payload) {
    if (_socket == null) {
      _log('Send failed: channel is not open');
      throw Exception('Channel is not open');
    }
    final header = ByteData(5)
      ..setUint8(0, type)
      ..setUint32(1, payload.length, Endian.big);
    _socket!.add(header.buffer.asUint8List());
    if (payload.isNotEmpty) _socket!.add(payload);
  }

  @override
  Future<void> sendFile(FileMetadata metadata) async {
    if (_socket == null) {
      _log('sendFile failed: channel is not open.');
      throw Exception('Channel is not open.');
    }

    final file = File(metadata.filePath);
    if (!await file.exists()) {
      _log('sendFile failed: file does not exist at ${metadata.filePath}');
      throw Exception('File not found: ${metadata.filePath}');
    }

    _log(
      'Starting file transfer: ${metadata.fileName} (${metadata.fileSize} bytes, id: ${metadata.fileId})',
    );

    _writeFrame(_typeFileStart, utf8.encode(metadata.toJson()));
    // Reset progress counter for this file
    if (!_bytesController.isClosed) _bytesController.add(0);

    int bytesSent = 0;
    // openRead streams the file off disk in OS-sized chunks
    // never holds the whole file in memory
    await for (final List<int> chunk in file.openRead()) {
      _writeFrame(_typeFileChunk, chunk);
      bytesSent += chunk.length;
      if (!_bytesController.isClosed) _bytesController.add(bytesSent);
    }

    _writeFrame(_typeFileEnd, const []);
    await _socket!.flush();
    _log(
      'File transfer complete: ${metadata.fileName} ($bytesSent bytes sent)',
    );
  }

  @override
  Future<FileMetadata> receiveFile(String saveDirectory) async {
    _currentSaveDirectory = saveDirectory;
    final completer = Completer<FileMetadata>();
    _receiveQueue.add(completer);
    _log('Awaiting incoming file into directory: $saveDirectory');

    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _log('receiveFile timed out waiting for file');
        _receiveQueue.remove(completer);
        throw Exception('Timed out waiting for incoming file');
      },
    );
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      _log('close() called but channel is already closed, Ignoring');
      return;
    }
    _isClosed = true;

    _log('Closing channel and tearing down socket connections');

    // Let any in flight finish tasks (sink close + queue completion)
    // settle before tearing down, so we don't race a completer resolving
    // against the queue being cleared/error'd out below
    try {
      await _finishChain;
    } catch (_) {
      // ignore
    }

    await _incomingFileSink?.close();
    await _socketSubscription?.cancel();
    await _socket?.close();
    await _serverSocket?.close();

    _socket = null;
    _serverSocket = null;
    _socketSubscription = null;
    _incomingFileSink = null;
    _incomingMetadata = null;
    _messageQueue.clear();

    for (final completer in _receiveQueue) {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Channel closed before file was received'),
        );
      }
    }
    _receiveQueue.clear();

    // Close and recreate the progress stream so it is fresh if the
    // channel object is reused for a subsequent session.
    await _bytesController.close();
    _bytesController = StreamController<int>.broadcast();

    _finishChain = Future.value(); // reset in case the channel is reused
    _log('Channel closed');
  }
}
