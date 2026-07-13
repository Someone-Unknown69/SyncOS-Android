// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/clipboard/provider/local_clipboard_sender_provider.dart';
import 'package:syncos_android/features/media/provider/remote_media_provider.dart';

import '../../core/network/domain/i_connection_manager.dart';
import '../../core/network/provider/connection_provider.dart';
import 'package:syncos_android/features/media/ui/music_player.dart';
import '../components/dashboard_item.dart';
import '../../theme/app_theme.dart';
import 'widgets/connection_status.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/dashboard_header.dart';
import 'package:syncos_android/core/config/app_routes.dart';
import 'package:syncos_android/core/config/app_router.dart';

final _connectionStatusStreamProvider = StreamProvider<ConnectionStatus>((ref) {
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
      onTap: () => AppRouter.pushRoute(context, AppRoutes.fileTransfer),
    ),
    DashboardItem(
      label: 'Run Command',
      icon: Icons.terminal,
      onTap: () => {AppRouter.pushRoute(context, AppRoutes.runCommands)},
    ),
    DashboardItem(
      label: 'Send Clipboard',
      icon: Icons.document_scanner,
      onTap: () {
        final localClipboardSender = ref.read(localClipboardSenderProvider);
        localClipboardSender.sendClipBoardContent();
      },
    ),
    DashboardItem(
      label: 'Gamepad',
      icon: Icons.gamepad,
      onTap: () => {AppRouter.pushRoute(context, AppRoutes.gamepad)},
    ),
  ];

  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _initializeMedia);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeMedia());
  }

  void _initializeMedia() {
    ref.read(remoteMediaServiceProvider).start();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatusAsync = ref.watch(_connectionStatusStreamProvider);

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
              loading: () => StatusDisconnected(),
              error: (error, stackTrace) => StatusDisconnected(),
              data: (connectionStatus) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (connectionStatus == ConnectionStatus.connected) ...[
                      const Header(),
                      DashboardGrid(items: _items),
                      const SizedBox(height: AppTheme.spacing),

                      Consumer(
                        builder: (context, ref, child) {
                          final info = ref
                              .watch(remoteMediaStreamProvider)
                              .value;
                          return (info != null && info.isValid)
                              ? const MusicPlayerWidget()
                              : const SizedBox.shrink();
                        },
                      ),
                    ] else ...[
                      StatusDisconnected(),
                    ],
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
