import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_controller/services/socket_client.dart';
import 'package:external_path/external_path.dart';
import '../core/notifications.dart';

class FileTransfer {
  static const int _ephemeralPort = 0;

  Future<void> sendFile(String filePath, {void Function(double)? onProgress}) async {
    final file = File(filePath);

    if(!await file.exists()) return;

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = await file.length();

    // calculate checksum of file
    debugPrint('[FTP] Calculating checksum for $fileName');
    final checksum = await _calculateChecksum(file);

    // starting a side port
    final ftpServer = await ServerSocket.bind(InternetAddress.anyIPv4, _ephemeralPort);
    final port = ftpServer.port;
    debugPrint('[FTP] Side server listening on port $port');

    // send metadata packet
    SocketClient.instance.send('file_transfer', 'recieve', {
      'fileName': fileName,
      'fileSize': fileSize,
      'checksum': checksum,
      'ftpPort' : port,
      'mimeType': 'application/octet-stream', // willl add more compatablity
    });

    int sentSize = 0;

    // wait for the accepted reply from peer
    try {
      final socket = await ftpServer.first.timeout(const Duration(seconds: 10));
      debugPrint('[FTP] Phone connected to side socket. Starting stream');
      final reader = file.openRead();

      await for (List<int> chunk in reader) {
        socket.add(chunk);
        sentSize += chunk.length;
        if (onProgress != null) onProgress(sentSize / fileSize);
      }

      await socket.addStream(reader);
      await socket.flush();
      await socket.close();
    } catch (e) {
      debugPrint('[FTP] Error or Timeout waiting for phone: $e');
    } finally {
      await ftpServer.close();
    }
  }

  Future<void> recieveFile (Map<String, dynamic> metadata, {void Function(double)? onProgress}) async {
    debugPrint("[FTP] Starting file recieve");
    final ftpPort = metadata['ftpPort'];
    final fileName = metadata['fileName'];
    final expectedChecksum = metadata['checksum'];
    final fileSize = metadata['fileSize'];

    final notif = ProgressNotification();
    const int notifID = 101; 

    final directoryPath = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
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

    final ftpSocket = await Socket.connect(SocketClient.instance.serverIP, ftpPort);
    int receivedSize = 0;
    final sink = file.openWrite();

    // Initializing notification
    await notif.displayNotif(
      id: notifID,
      title: "Receiving $fileName",
      body: fileName,
      progress: 0,
      isOngoing: true,
    );

    await for (List<int> chunk in ftpSocket) {
      sink.add(chunk);
      receivedSize += chunk.length;
      double progress = receivedSize / fileSize;
      if (onProgress != null) onProgress(progress);

      int currentPercent = (progress * 100).toInt();
      if (currentPercent % 5 == 0) {
        // Transferring notification
        notif.displayNotif(
          id: notifID,
          title: "Receiving $fileName",
          body: fileName,
          progress: currentPercent,
          isOngoing: true,
        );
      }

    }
    
    await sink.flush();
    await sink.close();
    await ftpSocket.close();
    
    final actualChecksum = await _calculateChecksum(file);
    if (actualChecksum == expectedChecksum) {
      debugPrint("[FTP] Transfer Successful: Checksum Matches");

      // Transfer complete notification
      await notif.displayNotif(
        id: notifID,
        title: "Transfer Complete",
        body: fileName,
        progress: 100,
        isOngoing: false, 
      );
    } else {
      debugPrint("[FTP] Transfer Failed: Checksum Mismatch!");
      await file.delete(); // Delete corrupted file

      // error notification
      await notif.showErrorNotif(
        id: 101, 
        fileName: fileName,
      );
    }
  }

  // SHA-256 checksum
  Future<String> _calculateChecksum(File file) async {
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  // select file to transfer
  Future<String?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: false, // Set true to sync multiple files
        type: FileType.any,    // restrict to .mp4, .pdf, etc. if needed
      );

      // Check if the user picked a file or cancelled
      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        debugPrint('[FTP] Selected file: $filePath');
        return filePath;
      } else {
        // user canceled the picker
        debugPrint('[FTP] User canceled the selection.');
        return null;
      }
    } catch (e) {
      debugPrint('[FTP] Error picking file: $e');
      return null;
    }
  }
}