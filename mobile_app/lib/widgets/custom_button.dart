import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color bg, fg;
  final double height;
  final bool outlined;

  const Btn(
      {super.key,
      required this.label,
      this.onTap,
      this.loading = false,
      this.icon,
      this.bg = AppColors.primary,
      this.fg = Colors.white,
      this.height = 52,
      this.outlined = false});

  const Btn.outline(
      {super.key,
      required this.label,
      this.onTap,
      this.loading = false,
      this.icon,
      this.bg = Colors.transparent,
      this.fg = AppColors.primary,
      this.height = 52})
      : outlined = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: outlined
            ? Colors.transparent
            : (onTap == null ? AppColors.border : bg),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: outlined ? Border.all(color: fg, width: 1.5) : null,
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(color: fg, strokeWidth: 2))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[
                        Icon(icon,
                            color: onTap == null ? AppColors.textTertiary : fg,
                            size: 17),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: onTap == null ? AppColors.textTertiary : fg,
                          )),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

class SmallBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color, bg;
  const SmallBtn(
      {super.key,
      required this.label,
      required this.onTap,
      this.icon,
      this.color = AppColors.primary,
      this.bg = AppColors.primaryFaint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5)
          ],
          Text(label,
              style: GoogleFonts.dmSans(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
