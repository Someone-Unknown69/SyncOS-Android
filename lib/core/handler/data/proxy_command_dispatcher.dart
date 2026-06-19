// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/handler/domain/i_command_dispatcher.dart';
import 'package:syncos_android/core/misc/app_logging.dart';
import 'package:syncos_android/features/file_transfer/data/file_transfer_service.dart';
import 'package:syncos_android/features/battery/provider/remote_battery_state.dart';
import 'package:syncos_android/features/device_info/provider/remote_device_info_state.dart';

class ProxyCommandDispatcher implements ICommandDispatcher {
  final _service = FlutterBackgroundService();
  final Ref ref;
  final FileTransferService _fileTransferService;

  StreamSubscription? _uiSubscription;
  bool _isStarted = false;

  ProxyCommandDispatcher(this.ref, this._fileTransferService) {
    _initListeners();
  }

  void _initListeners() {
    _uiSubscription?.cancel();
    _uiSubscription = _service.on('update_ui_event').listen((event) {
      if (event == null) return;

      final String operation = event['operation'];
      final String action = event['action'];
      final Map<String, dynamic> args = event['args'];

      logDebug('Command Dispatcher', 'Recieved: $operation');

      switch (operation) {
        case 'battery_info':
          ref
              .read(batteryProvider.notifier)
              .update(args['level'] ?? 0, args['status'] ?? false);
          break;
        case 'device_info':
          ref.read(deviceInfoProvider.notifier).update(args['name']);
          break;
        case 'file_transfer':
          if (action == 'receive') {
            _fileTransferService.recieveFile(args);
          } else if (action == 'send') {
            // will add ability to send file requests in future
          }
          break;
      }
    });
  }

  @override
  void start() {
    if (_isStarted) return;
    _isStarted = true;
  }

  @override
  void stop() {
    _uiSubscription?.cancel();
    _uiSubscription = null;
    _isStarted = false;
  }
}
