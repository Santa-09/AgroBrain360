import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class ACard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color, borderColor;
  final VoidCallback? onTap;
  final double radius;
  const ACard(
      {super.key,
      required this.child,
      this.padding,
      this.color,
      this.borderColor,
      this.onTap,
      this.radius = 16});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? AppColors.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: child,
        ),
      );
}

class SectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionLabel(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary))),
        if (action != null)
          GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: GoogleFonts.dmSans(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600))),
      ]);
}

class KVRow extends StatelessWidget {
  final String k, v;
  final Color? valueColor;
  const KVRow(this.k, this.v, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(k,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textTertiary)),
          const Spacer(),
          Text(v,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ]),
      );
}

class ModCard extends StatelessWidget {
  final String title, sub;
  final IconData icon;
  final Color accent, faint;
  final VoidCallback onTap;
  final String? tag;
  const ModCard(
      {super.key,
      required this.title,
      required this.sub,
      required this.icon,
      required this.accent,
      required this.faint,
      required this.onTap,
      this.tag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: faint, borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, color: accent, size: 21)),
              const Spacer(),
              if (tag != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: faint, borderRadius: BorderRadius.circular(5)),
                  child: Text(tag!,
                      style: GoogleFonts.dmSans(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                )
              else
                Container(
                    width: 28,
                    height: 28,
                    decoration:
                        BoxDecoration(color: faint, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: accent, size: 14)),
            ]),
            const Spacer(),
            Text(title,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1)),
            const SizedBox(height: 3),
            Text(sub,
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textTertiary, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}
