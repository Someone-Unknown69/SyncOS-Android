// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'dart:typed_data';
import 'package:syncos_android/core/network/domain/connection_config.dart';

abstract class IControllerTransferService {
    Future<void> connect(ConnectionConfig config);
    void sendUpdate(Uint8List payload);
    Future<void> disconnect();
}
