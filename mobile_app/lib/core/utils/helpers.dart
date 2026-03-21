import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../../services/language_service.dart';

class H {
  static String rupees(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0)
          .format(v);

  static String compact(double v) {
    if (v >= 100000) return '\u20B9${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '\u20B9${(v / 1000).toStringAsFixed(1)}K';
    return '\u20B9${v.toStringAsFixed(0)}';
  }

  static String greeting() => LangSvc().greeting();

  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return _tr('justNow', 'Just now');
    if (diff.inMinutes < 60) {
      return LangSvc().format('minutesAgo', '{value}m ago', diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return LangSvc().format('hoursAgo', '{value}h ago', diff.inHours);
    }
    if (diff.inDays < 7) {
      return LangSvc().format('daysAgo', '{value}d ago', diff.inDays);
    }
    return date(d);
  }

  static String fhiLabel(int s) {
    if (s >= 80) return _tr('excellent', 'Excellent');
    if (s >= 60) return _tr('good', 'Good');
    if (s >= 40) return _tr('fair', 'Fair');
    if (s >= 20) return _tr('poor', 'Poor');
    return _tr('critical', 'Critical');
  }

  static Color fhiColor(int s) {
    if (s >= 80) return AppColors.success;
    if (s >= 60) return AppColors.primary;
    if (s >= 40) return AppColors.amber;
    if (s >= 20) return AppColors.warning;
    return AppColors.danger;
  }

  static Color riskColor(String r) {
    switch (r.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.amber;
      case 'high':
        return AppColors.warning;
      case 'critical':
        return AppColors.danger;
      default:
        return AppColors.textTertiary;
    }
  }

  static String dist(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  static String cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  static String displayText(String value) => LangSvc().displayText(value);

  static void snack(BuildContext ctx, String msg, {bool error = false}) {
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? AppColors.danger : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  static String _tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }
}
