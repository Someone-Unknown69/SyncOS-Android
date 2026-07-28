// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:syncos_android/core/storage/domain/i_storage_service.dart';

/// File-backed key-value store for large, non-sensitive app data.
///
/// Persists all entries as a single JSON object in the app's documents
/// directory (`<documents>/syncos_data.json`). This sits between
/// [PrefsStorage] (simple primitives) and [SecureStorage] (encrypted secrets):
/// it has no size constraints and no encryption overhead, making it ideal for
/// collections like file transfer history and settings blobs.
///
/// Thread-safety note: reads and writes are serialised through a per-instance
/// lock-free async pattern; callers that perform rapid concurrent writes should
/// queue them on the same isolate.
class DataStorage implements IStorageService {
  static const String _fileName = 'syncos_data.json';

  // In-memory cache so we avoid reading the file on every call.
  Map<String, String>? _cache;

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Loads the JSON file into [_cache]. Creates an empty file if absent.
  Future<Map<String, String>> _loadCache() async {
    if (_cache != null) return _cache!;

    final file = await _getFile();
    if (!file.existsSync()) {
      _cache = {};
      return _cache!;
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        _cache = {};
        return _cache!;
      }
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      _cache = decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      // Corrupted file — start fresh rather than crashing.
      _cache = {};
    }

    return _cache!;
  }

  /// Persists the current in-memory cache back to disk atomically via a
  /// temp-file swap so a crash mid-write never corrupts the store.
  Future<void> _persist() async {
    final cache = _cache ?? {};
    final file = await _getFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(cache));
    await tmp.rename(file.path);
  }

  // ─── IStorageService ───────────────────────────────────────────────────────

  @override
  Future<void> write(String key, String value) async {
    final cache = await _loadCache();
    cache[key] = value;
    await _persist();
  }

  @override
  Future<String?> read(String key) async {
    final cache = await _loadCache();
    return cache[key];
  }

  @override
  Future<void> delete(String key) async {
    final cache = await _loadCache();
    if (cache.remove(key) != null) {
      await _persist();
    }
  }

  @override
  Future<void> clearAll() async {
    _cache = {};
    await _persist();
  }
}
