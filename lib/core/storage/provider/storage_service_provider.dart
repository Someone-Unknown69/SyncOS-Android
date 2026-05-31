import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/core/storage/data/prefs_storage.dart';
import 'package:mobile_controller/core/storage/data/secure_storage.dart';
import 'package:mobile_controller/core/storage/data/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
final pairedProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.isPaired;
});