import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/features/device_info/provider/device_info_notifier.dart';
import 'package:mobile_controller/features/battery/provider/battery_notifier.dart';
import 'package:mobile_controller/features/file_transfer/data/file_transfer_service.dart';
import 'package:mobile_controller/features/music/domain/i_media_service.dart';

class CommandDispatcher {
  final Ref ref;
  final IConnectionManager _connectionManager;
  final IMediaService _mediaService;
  final FileTransferService _fileTransferService;

  CommandDispatcher(
    this.ref,
    this._connectionManager, 
    this._mediaService,
    this._fileTransferService,
  ) {
    _init();
  }

  void _init() {
    _connectionManager.rawMessageStream.listen((rawMessage) {
      final Map<String, dynamic> data = jsonDecode(rawMessage);
      final String operation = data['op'];
      final String action = data['action'];
      final Map<String, dynamic> args = data['args'];

      debugPrint('[Dispatcher] : Recieved $data');

      switch(operation) {
        case 'music':
          if(action == 'update_metadata') {
            // ref.read(mediaServiceProvider.notifier)
          } else if (action == 'control') {
            _mediaService.sendControlCommand(action, args);
          }
          break;
        case 'battery_info':
          ref.read(batteryProvider.notifier).update(
            args['level'] ?? 0, 
            args['status'] ?? false
          );
          break;
        case 'device_info':
          ref.read(deviceInfoProvider.notifier).update(args['name']);
          break;
        case 'file_transfer':
          if(action == 'receive') {
            _fileTransferService.recieveFile(args);
          } else if(action == 'send') {} // will add ability to send too in future 
          break;
      }
    });
  }
}