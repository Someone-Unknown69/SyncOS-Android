import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/globals.dart';
import '../../models/dashboard_item.dart';
import '../../services/file_transfer.dart';
import '../../services/socket_client.dart';
import '../../services/storage_service.dart';
import '../../services/pairing_screen.dart';
import '../../theme/app_theme.dart';
import '../gamepad/gamepad_screen.dart';
import 'widgets/music_player.dart';
import 'widgets/connection_status.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/transfer_snackbar.dart';
import '../../core/notification_local.dart';
import 'widgets/header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {

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
        final notif = NotificationLocal();
        notif.initNotif();
        notif.displayNotif(
          id: 100, 
          title: 'wassup wid it', 
          body: 'bang bang skid skid nga'
        );
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent, 
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.only(
            left: AppTheme.padding,
            right: AppTheme.padding,
            bottom: AppTheme.padding,
            top: AppTheme.padding * 3, 
          ),
            child: ValueListenableBuilder<SocketConnectionState>(
              valueListenable: client.connectionStatus,
              builder: (context, connectionStatus, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (connectionStatus == SocketConnectionState.connected) ...[
                      const Header(),
        
                      DashboardGrid(items: _items),
                      const SizedBox(height: AppTheme.spacing),
        
                      ValueListenableBuilder(
                        valueListenable: processor.metadata, 
                        builder: (context, info, child) {
                          final bool isUnknown = info.title.toLowerCase() == 'unknown' || 
                                                info.artist.toLowerCase() == 'unknown' ||
                                                info.title.isEmpty || 
                                                info.artist.isEmpty;

                          if (isUnknown) {
                            return const SizedBox.shrink();
                          }

                          return MusicPlayerWidget(
                            imagePath: info.albumArt,
                            trackName: info.title,
                            artistName: info.artist,
                            position: info.position,
                            duration: info.duration,
                            status: info.status,
                            albumArtBase64: "",
                            client: client,
                          );
                        },
                      ),
        
                      
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
    );
  }
}
