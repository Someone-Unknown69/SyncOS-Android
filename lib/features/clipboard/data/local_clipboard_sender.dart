import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mobile_controller/core/network/domain/i_connection_manager.dart';
import 'package:mobile_controller/pages/components/snackbar.dart';

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