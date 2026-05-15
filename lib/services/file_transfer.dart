import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_controller/socket_client.dart';
import 'package:external_path/external_path.dart';
import '../main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();

// ------------------------------        FTP Implementation Class       -----------------------------------

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

// ----------------------------      Progress Notification    ---------------------------------------

class ProgressNotification {
  Future<void> initNotif() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotif.initialize(const InitializationSettings(android: androidInit));

    const channel = AndroidNotificationChannel(
      'basic_channel', // ID
      'Reminders',     // Name shown in system settings
      importance: Importance.high,
    );

    await localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> displayNotif({
    required int id,
    required String title,
    required String body,
    int progress = 0,
    bool isOngoing = true, 
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'transfer_channel',
      'File Transfer',
      channelDescription: 'Progress of SyncOS file transfers',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      ongoing: isOngoing, // Dynamic status
      autoCancel: !isOngoing, // Allows the notification to disappear when clicked after finishing
      
      actions: isOngoing ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'cancel_transfer',
          'CANCEL',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ] : null, // Remove cancel button when transfer is done
    );

    await localNotif.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showErrorNotif({
    required int id,
    required String fileName,
    String error = "Transfer failed or connection lost",
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'transfer_channel',
      'File Transfer',
      channelDescription: 'Progress of SyncOS file transfers',
      importance: Importance.high, // Higher importance so the user notices the failure
      priority: Priority.high,
      showProgress: false,         // Hide the progress bar on error
      ongoing: false,              // Allow user to swipe it away
      autoCancel: true,            // Dismiss when tapped
      color: Colors.red,         // RED !!!! RED !!!!!
      icon: '@mipmap/ic_launcher',
    );

    await localNotif.show(
      id,
      'Transfer Failed',
      '$fileName: $error',
      NotificationDetails(android: androidDetails),
    );
  }
}


// ----------------------------       Progress Snackbar     ---------------------------------------

class TransferSnackbar {
  static void show({
    required String label,
    required String fileName,
    required int fileSize,
    required ValueNotifier<double> progressNotifier,
    required Future<void> task,
    VoidCallback? onCancel,
  }) {
    final state = snackbarKey.currentState;
    final context = snackbarKey.currentContext;
    if (state == null || context == null) return;

    final theme = Theme.of(context);
    final String sizeStr = "${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB";

    state.hideCurrentSnackBar();
    state.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        // Removed fixed width and right-margin to cover the full bottom
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
        content: ValueListenableBuilder<double>(
          valueListenable: progressNotifier,
          builder: (context, progress, child) {
            final bool isInitializing = progress <= 0;
            final bool isComplete = progress >= 1.0;
            final Color accentColor = isComplete ? Colors.green : theme.colorScheme.primary;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isComplete ? Icons.check_circle : (isInitializing ? Icons.hourglass_top : Icons.sync),
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isComplete ? "Success" : (isInitializing ? "Initializing" : label),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!isInitializing && !isComplete)
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // File Information
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isInitializing ? "Preparing file for transfer..." : "Size: $sizeStr",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // The Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: isInitializing ? null : (isComplete ? 1.0 : progress),
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (!isComplete && onCancel != null) onCancel();
                        snackbarKey.currentState?.hideCurrentSnackBar();
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: isComplete ? Colors.green : theme.colorScheme.error,
                      ),
                      child: Text(isComplete ? "DISMISS" : "CANCEL"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    task.then((_) {
      progressNotifier.value = 1.0;
      Future.delayed(const Duration(seconds: 3), () {
        snackbarKey.currentState?.hideCurrentSnackBar();
      });
    }).catchError((e) {
      _showError("Transfer Failed: $e");
    });
  }

  static void _showError(String msg) {
    snackbarKey.currentState?.hideCurrentSnackBar();
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}