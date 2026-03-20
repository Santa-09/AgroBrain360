import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_card.dart';

class CropOptionsScreen extends StatelessWidget {
  const CropOptionsScreen({super.key});

  String t(String key) => LangSvc().t(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('cropLabel')),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('chooseCropTask'),
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('chooseCropTaskSub'),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _OptionCard(
              title: t('diseaseDetection'),
              subtitle: t('diseaseDetectionSub'),
              icon: Icons.health_and_safety_rounded,
              accent: AppColors.cropGreen,
              faint: AppColors.cropFaint,
              onTap: () => Navigator.pushNamed(context, Routes.cropDiseaseScan),
            ),
            const SizedBox(height: 14),
            _OptionCard(
              title: t('cropDetection'),
              subtitle: t('cropDetectionSub'),
              icon: Icons.spa_rounded,
              accent: AppColors.primary,
              faint: AppColors.primaryFaint,
              onTap: () => Navigator.pushNamed(context, Routes.cropDetectScan),
            ),
            const SizedBox(height: 14),
            _OptionCard(
              title: t('cropRecommendation'),
              subtitle: t('cropRecommendationSub'),
              icon: Icons.eco_rounded,
              accent: AppColors.cropGreen,
              faint: AppColors.cropFaint,
              onTap: () =>
                  Navigator.pushNamed(context, Routes.cropRecommendation),
            ),
            const SizedBox(height: 14),
            _OptionCard(
              title: t('fertilizerRecommendation'),
              subtitle: t('fertilizerRecommendationSub'),
              icon: Icons.science_rounded,
              accent: AppColors.info,
              faint: AppColors.infoFaint,
              onTap: () => Navigator.pushNamed(context, Routes.fertilizerInput),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color faint;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.faint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ACard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: faint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}
