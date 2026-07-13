// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/data/file_transfer_channel.dart';
import 'package:syncos_android/core/network/domain/i_file_transfer_channel.dart';

final fileTransferChannelProvider = Provider<IFileTransferChannel>((ref) {
  return FileTransferChannel();
});
