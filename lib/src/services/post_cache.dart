import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PostCache {
  static const _prefixPayload = 'cache_payload_';
  static const _prefixTimestamp = 'cache_timestamp_';

  Future<void> write(String key, List<dynamic> jsonPayload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefixPayload$key', jsonEncode(jsonPayload));
    await prefs.setInt(
      '$_prefixTimestamp$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<List<dynamic>?> read(
    String key, {
    Duration maxAge = const Duration(minutes: 10),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_prefixTimestamp$key');
    if (timestamp == null) {
      return null;
    }

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    if (age > maxAge) {
      return null;
    }

    final raw = prefs.getString('$_prefixPayload$key');
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    return decoded is List<dynamic> ? decoded : null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(_prefixPayload) ||
              key.startsWith(_prefixTimestamp),
        )
        .toList(growable: false);

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
