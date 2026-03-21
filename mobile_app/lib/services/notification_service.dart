import 'local_db_service.dart';
import 'language_service.dart';

enum AppNotifType { alert, tip, income, fhi, vet, sync, service, machinery }

class AppNotif {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final AppNotifType type;
  final bool read;

  const AppNotif({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.read,
  });

  AppNotif copyWith({bool? read}) => AppNotif(
        id: id,
        title: title,
        body: body,
        time: time,
        type: type,
        read: read ?? this.read,
      );
}

class NotificationSvc {
  static final NotificationSvc _i = NotificationSvc._();
  factory NotificationSvc() => _i;
  NotificationSvc._();

  String _t(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  List<AppNotif> list() {
    final notifications = <AppNotif>[];
    final scans = DB.getScans();
    final fhi = DB.getFHI();
    final pending = DB.pending();

    if (pending.isNotEmpty) {
      final latestQueuedAt = DateTime.tryParse(
            pending.first.value['queued_at']?.toString() ?? '',
          ) ??
          DateTime.now();
      notifications.add(
        _withState(
          AppNotif(
            id: 'sync_${pending.length}_${latestQueuedAt.toIso8601String()}',
            type: AppNotifType.sync,
            title: _t('offlineSyncPending', 'Offline Sync Pending'),
            body: LangSvc().format(
              'offlineSyncPendingBody',
              '{value} record(s) waiting to sync when internet is available.',
              pending.length,
            ).replaceFirst(
              'record(s)',
              pending.length == 1 ? 'record' : 'records',
            ),
            time: latestQueuedAt,
            read: false,
          ),
        ),
      );
    }

    if (fhi != null) {
      final updatedAt = DateTime.tryParse(fhi['updated_at']?.toString() ?? '') ?? DateTime.now();
      final overall = (fhi['overall_score'] as num? ?? 0).toInt();
      final recommendations = List<String>.from(fhi['recommendations'] ?? const []);
      notifications.add(
        _withState(
          AppNotif(
            id: 'fhi_${updatedAt.toIso8601String()}',
            type: AppNotifType.fhi,
            title: _t('farmHealthScoreUpdated', 'Farm Health Score Updated'),
            body: recommendations.isNotEmpty
                ? '${_t('fhiIs', 'FHI is')} $overall. ${LangSvc().displayText(recommendations.first)}'
                : '${_t('latestFarmHealthIndex', 'Your latest Farm Health Index is')} $overall.',
            time: updatedAt,
            read: updatedAt.isBefore(DateTime.now().subtract(const Duration(days: 2))),
          ),
        ),
      );
    }

    for (final scan in scans.take(5)) {
      final ts = DateTime.tryParse(scan['ts']?.toString() ?? '') ?? DateTime.now();
      final type = (scan['type'] as String? ?? 'crop').toLowerCase();
      final title = (scan['title'] as String? ?? '').trim();
      final result = (scan['result'] as String? ?? '').trim();
      final id = 'scan_${scan['_key'] ?? ts.toIso8601String()}';

      notifications.add(
        _withState(
          AppNotif(
            id: id,
            type: _scanType(type),
            title: _scanTitle(type, title),
            body: _scanBody(type, title, result),
            time: ts,
            read: ts.isBefore(DateTime.now().subtract(const Duration(days: 1))),
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      notifications.add(
        _withState(
          AppNotif(
            id: 'welcome_activity',
            type: AppNotifType.tip,
            title: _t('startYourFirstScan', 'Start Your First Scan'),
            body: _t(
              'notificationsAdaptBody',
              'Notifications will adapt to your crop, livestock, machinery, and farm health activity.',
            ),
            time: DateTime.now(),
            read: false,
          ),
        ),
      );
    }

    notifications.sort((a, b) => b.time.compareTo(a.time));
    return notifications.where((item) => DB.getNotificationMeta(item.id)['dismissed'] != true).toList();
  }

  int unreadCount() => list().where((item) => !item.read).length;

  Future<void> markRead(String id) => DB.markNotificationRead(id);

  Future<void> markAllRead() async {
    for (final item in list()) {
      await DB.markNotificationRead(item.id);
    }
  }

  Future<void> dismiss(String id) => DB.dismissNotification(id);

  AppNotif _withState(AppNotif notification) {
    final meta = DB.getNotificationMeta(notification.id);
    return notification.copyWith(read: meta['read'] == true || notification.read);
  }

  AppNotifType _scanType(String type) => switch (type) {
        'livestock' => AppNotifType.vet,
        'machinery' => AppNotifType.machinery,
        'residue' => AppNotifType.income,
        _ => AppNotifType.alert,
      };

  String _scanTitle(String type, String title) => switch (type) {
        'livestock' => _t('livestockCheckSaved', 'Livestock Check Saved'),
        'machinery' => _t('machineryUpdateSaved', 'Machinery Update Saved'),
        'residue' => _t('residueIncomeUpdate', 'Residue Income Update'),
        _ => title.isNotEmpty ? LangSvc().displayText(title) : _t('cropScanSaved', 'Crop Section Scan Saved'),
      };

  String _scanBody(String type, String title, String result) {
    if (result.isNotEmpty) {
      final translatedTitle = title.isEmpty ? '' : LangSvc().displayText(title);
      final translatedResult = LangSvc().displayText(result);
      return '$translatedTitle ${translatedTitle.isEmpty ? '' : '- '}${_t('resultLabel', 'Result')}: $translatedResult'.trim();
    }
    return switch (type) {
      'livestock' => _t('livestockHistoryNotice', 'Your latest livestock diagnosis was added to history.'),
      'machinery' => _t('machineryHistoryNotice', 'Your latest machinery recommendation and maintenance status were saved.'),
      'residue' => _t('residueHistoryNotice', 'Your latest residue income analysis is available in history.'),
      _ => _t('cropHistoryNotice', 'Your latest crop analysis is available in history.'),
    };
  }
}
