import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class CropRecommendationResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const CropRecommendationResultScreen({super.key, required this.data});

  String t(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  double get _confidence => (data['confidence'] as num? ?? 0).toDouble();
  List<dynamic> get _topRecommendations =>
      (data['top_recommendations'] as List?) ?? const [];

  @override
  Widget build(BuildContext context) {
    final cropName = H.displayText(
      data['crop']?.toString() ?? t('unknownLabel', 'Unknown'),
    );
    final source = data['source']?.toString() ?? 'offline';
    final summary = data['summary']?.toString();
    final description = data['description']?.toString();
    final sourceColor =
        source == 'offline' ? AppColors.info : AppColors.success;
    final sourceBg =
        source == 'offline' ? AppColors.infoFaint : AppColors.successFaint;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: AppColors.cropGreen,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.cropGreen,
                      AppColors.cropGreen.withValues(alpha: 0.84),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t('cropRecommendation', 'Crop Recommendation')
                            .toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          cropName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          t('confidenceLabel', 'Confidence'),
                          '${(_confidence * 100).toStringAsFixed(1)}%',
                          Icons.analytics_rounded,
                          AppColors.info,
                          AppColors.infoFaint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metric(
                          t('resultLabel', 'Result'),
                          t('recommendedLabel', 'Recommended'),
                          Icons.check_circle_rounded,
                          AppColors.cropGreen,
                          AppColors.cropGreen.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metric(
                          t('sourceLabel', 'Source'),
                          source == 'offline'
                              ? t('offlineLabel', 'Offline')
                              : t('cloudLabel', 'Cloud'),
                          source == 'offline'
                              ? Icons.wifi_off_rounded
                              : Icons.cloud_done_rounded,
                          sourceColor,
                          sourceBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ACard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heading(
                          t('recommendedCropLabel', 'Recommended Crop'),
                          Icons.agriculture_rounded,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          cropName,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cropGreen,
                          ),
                        ),
                        if ((summary?.isNotEmpty ?? false) ||
                            (description?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: 10),
                          Text(
                            (summary?.isNotEmpty ?? false)
                                ? summary!
                                : description!,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_topRecommendations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ACard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heading(
                            t('topRecommendations', 'Top Recommendations'),
                            Icons.leaderboard_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._topRecommendations.map(
                            (item) {
                              final map = item is Map<String, dynamic>
                                  ? item
                                  : Map<String, dynamic>.from(
                                      item as Map<dynamic, dynamic>);
                              final name = H.displayText(
                                map['crop']?.toString() ??
                                    map['label']?.toString() ??
                                    t('unknownLabel', 'Unknown'),
                              );
                              final confidence =
                                  (map['confidence'] as num? ?? 0).toDouble();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(confidence * 100).toStringAsFixed(1)}%',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.cropGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (source == 'offline') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.infoFaint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: AppColors.info, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t(
                                'offlineCropRecommendationResult',
                                'Offline recommendation generated from the on-device crop model.',
                              ),
                              style: GoogleFonts.dmSans(
                                color: AppColors.info,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Btn(
                    label: t('recommendAgain', 'Recommend Again'),
                    icon: Icons.restart_alt_rounded,
                    bg: AppColors.cropGreen,
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      Routes.cropRecommendation,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style:
                GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _heading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cropGreen, size: 15),
        const SizedBox(width: 7),
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
