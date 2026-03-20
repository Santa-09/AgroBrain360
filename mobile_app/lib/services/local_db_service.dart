import 'package:hive_flutter/hive_flutter.dart';

class DB {
  static const _user = 'user_box';
  static const _scans = 'scans_box';
  static const _sync = 'sync_box';
  static const _fhi = 'fhi_box';
  static const _notifications = 'notification_box';

  static Box? _boxOrNull(String name) => Hive.isBoxOpen(name) ? Hive.box(name) : null;

  static String currentUserId() {
    final user = getUser();
    return user?['user_id'] ?? user?['id'] ?? user?['phone'] ?? 'guest';
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    for (final b in [_user, _scans, _sync, _fhi, _notifications]) await Hive.openBox(b);
  }

  // ── User ──────────────────────────────────────────────────
  static Future<void> saveUser(Map<String, dynamic> u) =>
      Hive.box(_user).put('me', u);

  static Map<String, dynamic>? getUser() {
    final box = _boxOrNull(_user);
    if (box == null) return null;
    final v = box.get('me');
    return v != null ? Map<String, dynamic>.from(v as Map) : null;
  }

  static Future<void> clearUser() => Hive.box(_user).clear();

  // ── Scans history ─────────────────────────────────────────

  /// Saves a scan. Injects `_key` into the stored map so
  /// [ScanHistoryScreen] can identify and delete individual items.
  static Future<void> saveScan(String key, Map<String, dynamic> s) async {
    final userId = currentUserId();
    final data = Map<String, dynamic>.from(s)
      ..['_key'] = key
      ..['scan_key'] = s['scan_key'] ?? key
      ..['user_id'] = s['user_id'] ?? userId;

    await Hive.box(_scans).put(key, data);
    await addSyncRecord(
      module: 'history',
      payload: {
        ...data,
        'scan_key': data['scan_key'] ?? key,
      },
    );
  }

  static List<Map<String, dynamic>> getScans() {
    final box = _boxOrNull(_scans);
    if (box == null) return [];

    final currentUserId = DB.currentUserId();

    return box.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .where((scan) => (scan['user_id'] ?? currentUserId) == currentUserId)
        .toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['ts'] as String? ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['ts'] as String? ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });
  }

  static Future<void> deleteScan(dynamic key) => Hive.box(_scans).delete(key);

  /// Deletes only the current user's scans.
  static Future<void> clearScans() async {
    final box = Hive.box(_scans);
    final currentUserId = DB.currentUserId();
    final keysToDelete = box.toMap().entries.where((entry) {
      final scan = Map<String, dynamic>.from(entry.value as Map);
      return (scan['user_id'] ?? currentUserId) == currentUserId;
    }).map((entry) => entry.key).toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  static Iterable<dynamic> scanKeys() => Hive.box(_scans).keys;

  static Future<void> mergeRemoteScans(List<Map<String, dynamic>> scans) async {
    final box = Hive.box(_scans);
    final currentUserId = DB.currentUserId();
    for (final scan in scans) {
      final key = (scan['scan_key'] ?? scan['_key'])?.toString().trim();
      if (key == null || key.isEmpty) continue;
      final normalized = Map<String, dynamic>.from(scan)
        ..['_key'] = key
        ..['scan_key'] = key
        ..['user_id'] = scan['user_id'] ?? currentUserId;
      await box.put(key, normalized);
    }
  }

  // ── FHI ───────────────────────────────────────────────────
  static Future<void> saveFHI(Map<String, dynamic> f) =>
      Hive.box(_fhi).put('latest', f);

  static Map<String, dynamic>? getFHI() {
    final box = _boxOrNull(_fhi);
    if (box == null) return null;
    final v = box.get('latest');
    return v != null ? Map<String, dynamic>.from(v as Map) : null;
  }

  // ── Sync queue ────────────────────────────────────────────
  static Future<void> addSyncRecord({
    required String module,
    required Map<String, dynamic> payload,
  }) {
    final user = getUser();
    final record = {
      'user_id': user?['user_id'] ?? user?['id'] ?? 0,
      'module': module,
      'payload': payload,
      'queued_at': DateTime.now().toIso8601String(),
    };
    return Hive.box(_sync).put(
      DateTime.now().millisecondsSinceEpoch.toString(),
      record,
    );
  }

  static List<MapEntry<dynamic, Map<String, dynamic>>> pending() =>
      (_boxOrNull(_sync)?.toMap().entries ?? const Iterable.empty())
          .map(
            (e) => MapEntry(e.key, Map<String, dynamic>.from(e.value as Map)),
          )
          .toList();

  static Future<void> removeSync(dynamic key) => Hive.box(_sync).delete(key);

  // Notifications state
  static Map<String, dynamic> getNotificationMeta(String id) {
    final box = _boxOrNull(_notifications);
    if (box == null) return const {};
    final value = box.get(id);
    return value != null ? Map<String, dynamic>.from(value as Map) : const {};
  }

  static Future<void> saveNotificationMeta(String id, Map<String, dynamic> meta) =>
      Hive.box(_notifications).put(id, meta);

  static Future<void> markNotificationRead(String id) async {
    final meta = getNotificationMeta(id);
    await saveNotificationMeta(id, {
      ...meta,
      'read': true,
    });
  }

  static Future<void> dismissNotification(String id) async {
    final meta = getNotificationMeta(id);
    await saveNotificationMeta(id, {
      ...meta,
      'dismissed': true,
    });
  }
}
