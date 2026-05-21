import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/globals.dart';
import '../../models/dashboard_item.dart';
import '../../services/file_transfer.dart';
import '../../services/socket_client.dart';
import '../../services/storage_service.dart';
import '../../services/pairing_screen.dart';
import '../../theme/app_theme.dart';
import '../gamepad/gamepad_screen.dart';
import '../music/music_player.dart';
import 'widgets/connection_status.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/transfer_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {

  // Dashboard Items
  late final List<DashboardItem> _items = [
    DashboardItem(
      label: 'Send Files',
      icon: Icons.file_copy,
      onTap: () async {
        final transfer = FileTransfer();
        final String? filePath = await transfer.pickFile();

        if(filePath == null) {
          debugPrint("[FTP] User cancelled file selection");
          return;
        }

        final file = File(filePath);
        final fileName = file.path.split(Platform.pathSeparator).last;
        final fileSize = await file.length();

        final progress = ValueNotifier<double>(0.0);
          
        final task = transfer.sendFile(
          filePath,
          onProgress: (p) => progress.value = p,
        );

        TransferSnackbar.show(
          label: "Sending File",
          fileName: fileName,
          fileSize: fileSize,
          progressNotifier: progress,
          task: task,
          onCancel: () {
            debugPrint("[FTP] File : $fileName Transfer Cancelled");
          }
        );
      },
    ),
    DashboardItem(
      label: 'Run Command',
      icon: Icons.terminal,
      onTap: () async {
        client.send('notification', 'receive', {
          'app': 'Whatsapp',
          'body' : 'u got a message nigga',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'color': 0xFF1DB954
        });
        // Implementation for Run Command
      },
    ),
    DashboardItem(
      label: 'Send Clipboard',
      icon: Icons.document_scanner,
      onTap: () => (),
    ),
    DashboardItem(
      label: 'Gamepad',
      icon: Icons.gamepad,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ControllerPage()),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleConnect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final s = client.connectionStatus.value;
      if (s == SocketConnectionState.disconnected || s == SocketConnectionState.reconnecting) {
        _handleConnect();
      }
    }
  }

  // Method to handle connection
  void _handleConnect() async {
    final ip = StorageService.serverIp;
    final port = StorageService.serverPort;
    final token = StorageService.pairingToken;
    if (ip != null && port != null) {
      await client.connect(ip, port, token: token);
    } else {
      // Data missing, reset to Pairing
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PairingScreen()));
      }
    }
  }

  @override
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this);
    client.handleDisconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //GestureDetector handles tapping "empty space" to hide keyboard
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SyncOS"),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: ValueListenableBuilder<SocketConnectionState>(
                valueListenable: client.connectionStatus,
                builder: (context, connectionStatus, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (connectionStatus == SocketConnectionState.connected) ...[
                        const StatusConnected(),
                        const SizedBox(height: AppTheme.spacing),

                        ValueListenableBuilder(
                          valueListenable: processor.metadata, 
                          builder: (context, info, child) {
                            return MusicPlayerWidget(
                              imagePath: info.albumArt,
                              trackName: info.title,
                              artistName: info.artist,
                              position: info.position,
                              duration: info.duration,
                              status: info.status,
                              albumArtBase64: "", // Not used directly in base64 anymore
                              client: client, // Pass client for seek ops
                            );
                          },
                        ),

                        const SizedBox(height: AppTheme.spacing),
                        DashboardGrid(items: _items),
                        
                      ] else if (connectionStatus == SocketConnectionState.connecting) ...[
                        const StatusWaiting(message: 'Connecting to Server...'),
                      ] else if (connectionStatus == SocketConnectionState.reconnecting) ...[
                        const StatusWaiting(message: 'Connection lost. Reconnecting...'),
                      ] else ...[
                        StatusDisconnected(onReconnect: _handleConnect),
                      ]
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
