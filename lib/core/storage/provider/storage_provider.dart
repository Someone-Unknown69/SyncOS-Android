import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/i_storage_service.dart';
import '../data/storage_service_impl.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart!');
});

final storageServiceProvider = Provider<IStorageService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return StorageServiceImpl(prefs);
});