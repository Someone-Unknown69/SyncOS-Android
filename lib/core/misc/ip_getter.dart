// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'dart:io';
import 'package:syncos_android/core/misc/app_logging.dart';

class IpGetter {
  Future<String?> getCurrentIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        if (interface.name.contains('wlan') ||
            interface.name.contains('eth') ||
            interface.name.contains('en')) {
          for (var address in interface.addresses) {
            if (!address.isLoopback) return address.address;
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      logDebug(
        'IP Address',
        'Failed to determine interface adapter local network IP framework: $e',
      );
    }
    return null;
  }
}
