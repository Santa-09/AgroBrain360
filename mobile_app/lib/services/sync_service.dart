import '../core/constants/api_constants.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'local_db_service.dart';

class SyncSvc {
  static final SyncSvc _i = SyncSvc._();
  factory SyncSvc() => _i;
  SyncSvc._();
  bool _syncing = false;

  void init() => ConnSvc().stream.listen((online) {
        if (online && !_syncing) sync();
      });

  Future<void> sync() async {
    if (_syncing) return;
    if (!await ApiSvc().hasToken()) return;
    final items = DB.pending();
    if (items.isEmpty) return;
    _syncing = true;
    for (final e in items) {
      try {
        final module = e.value['module']?.toString();
        final res = await ApiSvc().post(
          module == 'history' ? ApiK.syncHistory : ApiK.sync,
          e.value,
        );
        if (res.ok) await DB.removeSync(e.key);
      } catch (_) {}
    }
    _syncing = false;
  }

  Future<void> restoreHistory({int limit = 200}) async {
    if (!await ApiSvc().hasToken()) return;
    final res = await ApiSvc().get(
      ApiK.syncHistory,
      q: {'limit': limit.toString()},
    );
    if (!res.ok || res.data == null) return;
    final payload = res.data!['data'] as Map<String, dynamic>? ?? res.data!;
    final rawItems = payload['items'];
    if (rawItems is! List) return;
    await DB.mergeRemoteScans(
      rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }
}
