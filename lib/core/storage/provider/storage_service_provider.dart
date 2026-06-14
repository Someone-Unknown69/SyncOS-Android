// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/domain/connection_config.dart';
import 'package:syncos_android/core/storage/data/prefs_storage.dart';
import 'package:syncos_android/core/storage/data/secure_storage.dart';
import 'package:syncos_android/core/storage/data/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';

// Provider for the underlying SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main.dart!');
});

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(SecureStorage(), PrefsStorage(prefs));
});

// Expose whether the app is paired (checks secure storage for pairing token)
final pairedProvider = StreamProvider<bool>((ref) async* {
  final storage = ref.watch(storageServiceProvider);

  final initialStatus = await storage.isPaired;
  yield initialStatus;

  final controller = StreamController<bool>();
  
  final sub1 = storage.pairingStream.listen(controller.add);
  final sub2 = FlutterBackgroundService().on('paired_status').listen((event) {
    if (event != null && event['isPaired'] != null) {
      controller.add(event['isPaired'] as bool);
    }
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  yield* controller.stream;
});

// for client config info
final clientConfigProvider = FutureProvider<ConnectionConfig?>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.getConnectionConfig();
});