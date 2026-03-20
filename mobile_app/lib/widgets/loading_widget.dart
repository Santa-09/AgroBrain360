import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final String? msg;
  const LoadingOverlay({super.key, this.msg});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withValues(alpha: 0.38),
        child: Center(
            child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12), blurRadius: 24)
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 3)),
            if (msg != null) ...[
              const SizedBox(height: 14),
              Text(msg!,
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary))
            ],
          ]),
        )),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final String? btnLabel;
  final VoidCallback? onBtn;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.sub,
      this.btnLabel,
      this.onBtn});

  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.primaryFaint, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.primary)),
          const SizedBox(height: 18),
          Text(title,
              style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(sub,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textTertiary, height: 1.5),
              textAlign: TextAlign.center),
          if (btnLabel != null && onBtn != null) ...[
            const SizedBox(height: 20),
            TextButton(
                onPressed: onBtn,
                child: Text(btnLabel!,
                    style: GoogleFonts.dmSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600))),
          ],
        ]),
      ));
}
