import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Brand ──────────────────────────────────────────
  static const Color primary = Color(0xFF1A5C2A);
  static const Color primaryDark = Color(0xFF0D3518);
  static const Color primaryMid = Color(0xFF236B33);
  static const Color primaryLight = Color(0xFF2E7D42);
  static const Color primaryFaint = Color(0xFFEAF4EC);
  static const Color primaryPale = Color(0xFFF2FAF4);

  // ── Accent ─────────────────────────────────────────────────
  static const Color amber = Color(0xFFE88C00);
  static const Color amberLight = Color(0xFFFFF3DC);
  static const Color amberBright = Color(0xFFFFB300);

  // ── Module tints ───────────────────────────────────────────
  static const Color cropGreen = Color(0xFF2E7D42);
  static const Color cropFaint = Color(0xFFEAF4EC);
  static const Color tealDark = Color(0xFF00695C);
  static const Color tealFaint = Color(0xFFE0F2F1);
  static const Color orangeDark = Color(0xFFBF360C);
  static const Color orangeFaint = Color(0xFFFBE9E7);
  static const Color indigoDark = Color(0xFF283593);
  static const Color indigoFaint = Color(0xFFE8EAF6);
  static const Color purpleDark = Color(0xFF4527A0);
  static const Color purpleFaint = Color(0xFFEDE7F6);
  static const Color goldDark = Color(0xFFF57F17);
  static const Color goldFaint = Color(0xFFFFFDE7);

  // ── Semantic ───────────────────────────────────────────────
  static const Color success = Color(0xFF1B7F4F);
  static const Color successFaint = Color(0xFFE6F7EE);
  static const Color warning = Color(0xFFB45309);
  static const Color warningFaint = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerFaint = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoFaint = Color(0xFFEFF6FF);

  // ── Neutrals ───────────────────────────────────────────────
  static const Color background = Color(0xFFF6F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFAFBF9);
  static const Color border = Color(0xFFDDE8DF);
  static const Color borderLight = Color(0xFFEDF2EE);
  static const Color divider = Color(0xFFF0F4F1);

  static const Color textPrimary = Color(0xFF111B13);
  static const Color textSecondary = Color(0xFF4D6554);
  static const Color textTertiary = Color(0xFF8BA393);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSub = Color(0xCCFFFFFF);

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D3518), Color(0xFF1A5C2A), Color(0xFF236B33)],
    stops: [0, 0.5, 1],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A5C2A), Color(0xFF2E7D42)],
  );

  static LinearGradient moduleGrad(Color c1, Color c2) => LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]);
}
