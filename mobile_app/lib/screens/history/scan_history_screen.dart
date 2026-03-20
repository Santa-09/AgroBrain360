import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/language_service.dart';
import '../../services/local_db_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<Map<String, dynamic>> _all = [];
  String _filter = 'All';

  static const _filters = [
    'All',
    'crop',
    'Livestock',
    'Machinery',
    'Residue',
  ];

  String t(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  String _filterLabel(String value) => switch (value) {
        'All' => t('allLabel', 'All'),
        'crop' => t('cropDisease', 'Crop Section'),
        'Livestock' => t('livestock', 'Livestock'),
        'Machinery' => t('machinery', 'Machinery'),
        'Residue' => t('residue', 'Residue'),
        _ => value,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  // FIX 1: Added `mounted` guard to prevent setState on a disposed widget.
  void _load() {
    if (!mounted) return;
    setState(() {
      _all = DB.getScans();
    });
  }

  List<Map<String, dynamic>> get _visible {
    if (_filter == 'All') return _all;
    return _all.where((s) {
      return (s['type'] as String? ?? '').toLowerCase() ==
          _filter.toLowerCase();
    }).toList();
  }

  // FIX 2: _delete now properly awaits deleteScan before calling _load.
  Future<void> _delete(Map<String, dynamic> scan) async {
    final key = scan['_key'] as String?;
    if (key != null) {
      await DB.deleteScan(key);
    }
    if (!mounted) return;
    _load();
  }

  Future<void> _deleteAll() async {
    await DB.clearScans();
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('scanHistory', 'Scan History')),
        backgroundColor: AppColors.surface,
        actions: [
          if (_all.isNotEmpty)
            TextButton(
              onPressed: _confirmClear,
              child: Text(
                t('clearAll', 'Clear All'),
                style: GoogleFonts.dmSans(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          /// FILTER CHIPS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final selected = _filters[i] == _filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _filter = _filters[i];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _filterLabel(_filters[i]),
                        style: GoogleFonts.dmSans(
                          color:
                              selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          /// SCAN LIST
          Expanded(
            child: _visible.isEmpty
                ? EmptyState(
                    icon: Icons.history_rounded,
                    title: t('noHistory', 'No scans yet'),
                    sub: t('noHistorySub', 'Your scan history will appear here'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: _visible.length,
                    itemBuilder: (_, i) => _tile(_visible[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> scan) {
    final type = scan['type'] as String? ?? 'crop';
    final (icon, color, bg) = _meta(type);
    final ts = DateTime.tryParse(
          scan['ts'] as String? ?? '',
        ) ??
        DateTime.now();

    return Dismissible(
      key: Key(
        scan['_key']?.toString() ?? scan.hashCode.toString(),
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),

      // FIX 3: onDismissed is now async and properly awaits _delete,
      // so _load() only runs after the Hive delete completes.
      onDismissed: (_) async => await _delete(scan),

      child: ACard(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            /// ICON
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            /// TEXT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan['title'] as String? ?? t('scan', 'Scan'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        H.ago(ts),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// RESULT TAG
            if (scan['result'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scan['result'] as String,
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _meta(String type) => switch (type) {
        'livestock' => (
            Icons.pets_rounded,
            AppColors.tealDark,
            AppColors.tealFaint,
          ),
        'machinery' => (
            Icons.agriculture_rounded,
            AppColors.orangeDark,
            AppColors.orangeFaint,
          ),
        'residue' => (
            Icons.recycling_rounded,
            AppColors.purpleDark,
            AppColors.purpleFaint,
          ),
        _ => (
            Icons.grass_rounded,
            AppColors.cropGreen,
            AppColors.cropFaint,
          ),
      };

  Future<void> _confirmClear() async {
    // Capture BuildContext synchronously BEFORE any await.
    // This satisfies `use_build_context_synchronously` and prevents accessing
    // a potentially-disposed context after the dialog future resolves.
    final dialogContext = context;

    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          t('clearAllHistory', 'Clear all history?'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          t('cannotBeUndone', 'This cannot be undone.'),
          style: GoogleFonts.dmSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            // Use the builder's own ctx — not the outer context after an await
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t('cancel', 'Cancel'),
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t('clearAll', 'Clear All'),
              style: GoogleFonts.dmSans(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    // Guard against widget being disposed while the dialog was open
    if (!mounted) return;

    if (ok == true) {
      await _deleteAll();
    }
  }
}
