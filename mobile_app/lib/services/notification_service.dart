import 'local_db_service.dart';

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
            title: 'Offline Sync Pending',
            body: '${pending.length} record${pending.length == 1 ? '' : 's'} waiting to sync when internet is available.',
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
            title: 'Farm Health Score Updated',
            body: recommendations.isNotEmpty
                ? 'FHI is $overall. ${recommendations.first}'
                : 'Your latest Farm Health Index is $overall.',
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
            title: 'Start Your First Scan',
            body: 'Notifications will adapt to your crop, livestock, machinery, and farm health activity.',
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
        'livestock' => 'Livestock Check Saved',
        'machinery' => 'Machinery Update Saved',
        'residue' => 'Residue Income Update',
        _ => title.isNotEmpty ? title : 'Crop Section Scan Saved',
      };

  String _scanBody(String type, String title, String result) {
    if (result.isNotEmpty) {
      return '$title ${title.isEmpty ? '' : '- '}Result: $result'.trim();
    }
    return switch (type) {
      'livestock' => 'Your latest livestock diagnosis was added to history.',
      'machinery' => 'Your latest machinery recommendation and maintenance status were saved.',
      'residue' => 'Your latest residue income analysis is available in history.',
      _ => 'Your latest crop analysis is available in history.',
    };
  }
}
