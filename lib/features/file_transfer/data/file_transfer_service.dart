import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/network/domain/i_connection_manager.dart';
import '../../../core/storage/domain/i_file_service.dart';
import '../../../core/network/domain/i_file_transfer_manager.dart';
import '../../../core/notification/domain/i_notification_service.dart';


// The sendFile method initiates a handshake by sending connectioninfo including size and checksum over 
// the command channel before streaming the file body. 
// RecieveFile acts as an entry point for incoming metadata, 
// Verifys the final checksum against the source. 

class FileTransferService {
  final IConnectionManager _channel;
  final IFileService _fileService;
  final IFileTransferManager _fileTransferManager;
  final INotificationService _notificationService;

  static const int _notifId = 101;

  FileTransferService(
    this._channel, 
    this._fileService, 
    this._fileTransferManager, 
    this._notificationService
  );

  Future<void> sendFile(String filePath, {void Function(double)? onProgress}) async {
    final file = File(filePath);

    if(!await file.exists()) return;

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = await file.length();

    // calculate checksum of file
    debugPrint('[FTP] Calculating checksum for $fileName');
    final checksum = await _fileService.calculateChecksum(file.path);

    final (sink, connectionInfo) = await _fileTransferManager.send();
    debugPrint('[FTP] Side server ready for connection with $connectionInfo');

    // send metadata packet
    _channel.send('file_transfer', 'recieve', {
      'fileName': fileName,
      'fileSize': fileSize,
      'checksum': checksum,
      'connectionInfo' : connectionInfo,
      'mimeType': 'application/octet-stream', // willl add more compatablity
    });

    int sentSize = 0;
    await for (List<int> chunk in file.openRead()) {
      sink.add(chunk);
      sentSize += chunk.length;
      double progress = sentSize / fileSize;
      
      if (onProgress != null) onProgress(progress);
      
      // Update notification every 5%
      if ((sentSize / fileSize * 100).toInt() % 5 == 0) {
        await _notificationService.showTransferProgress(
        id: _notifId, 
        fileName: fileName, 
        progress: progress
      );
      }
    }

    await sink.close();
    await _notificationService.dismissNotification(_notifId);
  }

  Future<void> recieveFile (Map<String, dynamic> metadata, {void Function(double)? onProgress}) async {
    debugPrint("[FTP] Starting file recieve");
    final connectionInfo = metadata['connectionInfo'];
    final fileName = metadata['fileName'];
    final expectedChecksum = metadata['checksum'];
    final fileSize = metadata['fileSize'];


    final directoryPath = await _fileService.getExternalStoragePath();
    String savePath = '$directoryPath/$fileName';
    File file = File(savePath);

    // handling duplicate files
    if(await file.exists()) {
      final String extension = fileName.contains('.') ? fileName.split('.').last : '';
      final String nameWithoutExtension = fileName.contains('.') 
          ? fileName.substring(0, fileName.lastIndexOf('.')) 
          : fileName;

      int counter = 1;
      while (await file.exists()) {
        // Construct new name: "test (1).file"
        savePath = '$directoryPath/$nameWithoutExtension ($counter).$extension';
        file = File(savePath);
        counter++;
      }
    } 

    final stream = await _fileTransferManager.receive(connectionInfo);
    final sink = file.openWrite();
    int receivedSize = 0;

    await for (List<int> chunk in stream) {
      sink.add(chunk);
      receivedSize += chunk.length;
      double progress = receivedSize / fileSize;
      
      if (onProgress != null) onProgress(progress);

      if ((receivedSize / fileSize * 100).toInt() % 5 == 0) {
        await _notificationService.showTransferProgress(
          id: _notifId, 
          fileName: fileName, 
          progress: progress
        );
      }
    }

    await sink.close();
    
    final actualChecksum = await _fileService.calculateChecksum(file.path);
    if (actualChecksum == expectedChecksum) {
      debugPrint("[FTP] Transfer Successful: Checksum Matches");
      await _notificationService.dismissNotification(_notifId);
    } else {
      debugPrint("[FTP] Transfer Failed: Checksum Mismatch!");
      await file.delete(); // Delete corrupted file
      await _notificationService.showTransferError(
        id: _notifId, 
        fileName: fileName, 
        error: "Checksum Mismatch"
      );
    }
  }

}