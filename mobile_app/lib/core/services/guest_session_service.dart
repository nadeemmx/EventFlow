import 'dart:convert';
import 'package:hive/hive.dart';

class GuestSessionService {
  static const String _boxName = 'eventflow_cache';
  static const String _guestKey = 'guest_session';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> startSession() async {
    await _box.put(_guestKey, jsonEncode({'is_guest': true}));
  }

  Future<void> endSession() async {
    await _box.delete(_guestKey);
  }

  bool isGuestSession() {
    final raw = _box.get(_guestKey);
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw as String);
      return decoded is Map && decoded['is_guest'] == true;
    } catch (_) {
      return false;
    }
  }
}
