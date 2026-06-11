import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/handler/domain/i_command_dispatcher.dart';
import 'package:mobile_controller/core/utils/app_logging.dart';
import 'package:mobile_controller/features/file_transfer/data/file_transfer_service.dart';
import 'package:mobile_controller/features/music/domain/i_local_media_sender.dart';
import 'package:mobile_controller/features/music/provider/remote_media_state.dart';
import 'package:mobile_controller/features/battery/provider/remote_battery_state.dart';
import 'package:mobile_controller/features/device_info/provider/remote_device_info_state.dart';

class ProxyCommandDispatcher implements ICommandDispatcher {
  final _service = FlutterBackgroundService();
  final Ref ref;
  final IMediaService _mediaService;
  final FileTransferService _fileTransferService;
  
  StreamSubscription? _uiSubscription;
  bool _isStarted = false;

  ProxyCommandDispatcher(
    this.ref,
    this._mediaService,
    this._fileTransferService,
  ) {
    _initListeners();
  }

  void _initListeners() {
    _uiSubscription?.cancel();
    _uiSubscription = _service.on('update_ui_event').listen((event) {
      if (event == null) return;

      final String operation = event['operation'];
      final String action = event['action'];
      final Map<String, dynamic> args = event['args'];

      logDebug('Command Dispatcher', 'Routing: $event');

      switch (operation) {
        case 'music':
          if (action == 'update_metadata') {
            ref.read(musicProvider.notifier).updateMetadata(args);
          } else if (action == 'control') {
            _mediaService.sendControlCommand(args);
          }
          break;
        case 'battery_info':
          ref.read(batteryProvider.notifier).update(
              args['level'] ?? 0, args['status'] ?? false);
          break;
        case 'device_info':
          ref.read(deviceInfoProvider.notifier).update(args['name']);
          break;
        case 'file_transfer':
          if (action == 'receive') {
            _fileTransferService.recieveFile(args);
          } else if(action == 'send') {
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
    
    // Explicitly sync state when service starts
    _service.invoke('request_global_sync');
    logDebug('Command Dispatcher', 'Proxy active and synced');
  }

  @override
  void dispatchCommand({
    required String operation,
    required String action,
    required Map<String, dynamic> args,
  }) {
    _service.invoke('send', {
      'op': operation,
      'action': action,
      'args': args,
    });
  }

  void requestGlobalSync() {
    _service.invoke('request_global_sync');
  }

  @override
  void stop() {
    _uiSubscription?.cancel();
    _uiSubscription = null;
    _isStarted = false;
  }
}