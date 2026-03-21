import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/helpers.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotif> _all = [];

  int get _unreadCount => _all.where((n) => !n.read).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _all = NotificationSvc().list();
    if (mounted) setState(() {});
  }

  String t(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  String _display(String value) => LangSvc().displayText(value);

  Future<void> _markAllRead() async {
    await NotificationSvc().markAllRead();
    _load();
  }

  Future<void> _markRead(String id) async {
    await NotificationSvc().markRead(id);
    _load();
  }

  Future<void> _delete(String id) async {
    await NotificationSvc().dismiss(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _all.where((n) => !n.read).toList();
    final read = _all.where((n) => n.read).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Text(t('notifications', 'Notifications')),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_unreadCount',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ]),
        backgroundColor: AppColors.surface,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                t('markAllRead', 'Mark all read'),
                style: GoogleFonts.dmSans(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _all.isEmpty
          ? _emptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                if (unread.isNotEmpty) ...[
                  _sectionLabel(t('newSection', 'New')),
                  const SizedBox(height: 8),
                  ...unread.map((n) => _tile(n)),
                  const SizedBox(height: 20),
                ],
                if (read.isNotEmpty) ...[
                  _sectionLabel(t('earlierSection', 'Earlier')),
                  const SizedBox(height: 8),
                  ...read.map((n) => _tile(n)),
                ],
              ],
            ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      );

  Widget _tile(AppNotif n) {
    final (icon, color, bg) = _meta(n.type);
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _delete(n.id),
      child: GestureDetector(
        onTap: () => _markRead(n.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.read ? AppColors.surface : AppColors.primaryFaint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.read
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          _display(n.title),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Text(
                      _display(n.body),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      H.ago(n.time),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _meta(AppNotifType t) => switch (t) {
        AppNotifType.alert => (
            Icons.warning_amber_rounded,
            AppColors.warning,
            AppColors.warningFaint
          ),
        AppNotifType.tip => (
            Icons.lightbulb_rounded,
            AppColors.amber,
            AppColors.amberLight
          ),
        AppNotifType.income => (
            Icons.currency_rupee_rounded,
            AppColors.success,
            AppColors.successFaint
          ),
        AppNotifType.fhi => (
            Icons.monitor_heart_rounded,
            AppColors.primary,
            AppColors.primaryFaint
          ),
        AppNotifType.vet => (
            Icons.pets_rounded,
            AppColors.tealDark,
            AppColors.tealFaint
          ),
        AppNotifType.sync => (
            Icons.sync_problem_rounded,
            AppColors.indigoDark,
            AppColors.indigoFaint
          ),
        AppNotifType.service => (
            Icons.location_on_rounded,
            AppColors.indigoDark,
            AppColors.indigoFaint
          ),
        AppNotifType.machinery => (
            Icons.agriculture_rounded,
            AppColors.orangeDark,
            AppColors.orangeFaint
          ),
      };

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryFaint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t('allCaughtUp', 'All caught up!'),
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('noNewNotifs', 'No new notifications'),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ]),
      );
}
