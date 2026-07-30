import 'dart:convert';
import 'package:hive/hive.dart';

class StorageService {
  static const String _boxName = 'eventflow_cache';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  dynamic get(String key) {
    return _box.get(key);
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> close() async {
    await _box.close();
  }

  Future<void> cacheJson(String key, dynamic data) async {
    await _box.put(key, jsonEncode(data));
  }

  T? getCachedJson<T>(String key, T Function(dynamic) fromJson) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw as String);
      return fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  List<T> getCachedJsonList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _box.get(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw as String) as List<dynamic>;
      return decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCache() async {
    final keys = _box.keys.where((k) => (k as String).startsWith('cache_'));
    for (final key in keys) {
      await _box.delete(key);
    }
  }
}
