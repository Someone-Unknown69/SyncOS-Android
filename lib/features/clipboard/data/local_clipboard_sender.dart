// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';
import 'package:syncos_android/pages/components/snackbar.dart';

class LocalClipboardSender {
  final IConnectionManager _networkChannel;
  String _clipboardCache = "";

  LocalClipboardSender(
    this._networkChannel,
  );

  Future<void> sendClipBoardContent() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardContent = data?.text;

      if(clipboardContent == null) {
        debugPrint('[Clipboard] Error while reading clipboard content');
        return;
      } 
      
      if(_clipboardCache != clipboardContent) {
        _networkChannel.send('clipboard', '', {'content' : data?.text});
        _clipboardCache = clipboardContent;

        AppSnackbar.show(message: 'Sent clipboard content');
      } else {
        AppSnackbar.show(message: 'No new clipboard content', isError: true);
      }

    } catch (e) {
      debugPrint('[Clipboard] $e');
    }
  }

}