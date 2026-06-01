import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/notification/provider/notification_provider.dart';
import 'package:mobile_controller/features/file_transfer/provider/file_transfer_provider.dart';

import '../../core/network/domain/i_connection_manager.dart';
import '../../core/network/provider/connection_provider.dart';
import '../../features/music/provider/remote_media_state.dart';
import 'package:mobile_controller/features/music/ui/music_player.dart';
import '../components/dashboard_item.dart';
import '../../theme/app_theme.dart';
import 'widgets/connection_status.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/dashboard_header.dart';
import 'package:mobile_controller/core/config/app_routes.dart';
import 'package:mobile_controller/core/config/app_router.dart';
import '../../core/network/provider/auto_connect_provider.dart';
final _connectionStatusStreamProvider =
  StreamProvider<ConnectionStatus>((ref) {
    final connectionManager = ref.watch(connectionManagerProvider);
    return connectionManager.connectionStatusStream;
  });

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  // Dashboard Items
  late final List<DashboardItem> _items = [
    DashboardItem(
      label: 'Send Files',
      icon: Icons.file_copy,
      onTap: () async {
        final fileTransferService = ref.read(fileTransferServiceProvider);
        fileTransferService.sendFile();
      },
    ),
    DashboardItem(
      label: 'Run Command',
      icon: Icons.terminal,
      onTap: () async {
        final notificationService = ref.read(notificationServiceProvider);

        notificationService.showTestNotification();
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
      onTap: () => {
        AppRouter.pushRoute(context, AppRoutes.gamepad),
      }
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final connectionStatusAsync = ref.watch(_connectionStatusStreamProvider);
    final mediaInfo = ref.watch(musicProvider);

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
            child: connectionStatusAsync.when(
              loading: () => const StatusWaiting(message: 'Connecting to Server...'),
              error: (error, stackTrace) => StatusDisconnected(onReconnect: () => ref.read(autoConnectProvider).manualReconnect()),
              data: (connectionStatus) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (connectionStatus == ConnectionStatus.connected) ...[
                      const Header(),
                      DashboardGrid(items: _items),
                      const SizedBox(height: AppTheme.spacing),
                      if (mediaInfo.isValid) const MusicPlayerWidget(),
                    ] else if (connectionStatus == ConnectionStatus.connecting) ...[
                      const StatusWaiting(message: 'Connecting to Server...'),
                    ] else if (connectionStatus == ConnectionStatus.reconnecting) ...[
                      const StatusWaiting(message: 'Connection lost. Reconnecting...'),
                    ] else ...[
                      StatusDisconnected(onReconnect: () => ref.read(autoConnectProvider).manualReconnect()),
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
