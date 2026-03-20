import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/health_score_widget.dart';

class HealthScoreScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const HealthScoreScreen({super.key, required this.data});

  String t(String key) => LangSvc().t(key);

  int get _score => (data['overall_score'] as num? ?? 0).toInt();
  Color get _color => H.fhiColor(_score);
  String get _label => data['label'] as String? ?? H.fhiLabel(_score);

  @override
  Widget build(BuildContext context) {
    final recs = List<String>.from(data['recommendations'] ?? []);
    final scores = [
      (
        t('cropCondition'),
        (data['crop_score'] as num? ?? 0).toInt(),
        AppColors.cropGreen
      ),
      (
        t('soilHealth'),
        (data['soil_score'] as num? ?? 0).toInt(),
        const Color(0xFF795548)
      ),
      (
        t('waterAccess'),
        (data['water_score'] as num? ?? 0).toInt(),
        AppColors.info
      ),
      (
        'Livestock',
        (data['livestock_score'] as num? ?? 0).toInt(),
        AppColors.tealDark
      ),
      (
        'Machinery',
        (data['machinery_score'] as num? ?? 0).toInt(),
        AppColors.orangeDark
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: _color,
          leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white))),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_color.withValues(alpha: 0.85), _color])),
              child: SafeArea(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const SizedBox(height: 36),
                    FHIGauge(score: _score, size: 140),
                    const SizedBox(height: 8),
                    Text(_label,
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text(t('farmHealth'),
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12)),
                  ])),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            // Score bars
            ACard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    const Icon(Icons.bar_chart_rounded,
                        color: AppColors.primary, size: 15),
                    const SizedBox(width: 7),
                    Text(t('categoryScores'),
                        style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 14),
                  ...scores.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child:
                          ScoreStrip(label: s.$1, score: s.$2, color: s.$3))),
                ])),
            const SizedBox(height: 14),

            // Score grid
            Row(
                children: scores
                    .take(5)
                    .map((s) => Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                    color: s.$3.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: s.$3.withValues(alpha: 0.2))),
                                child: Column(children: [
                                  Text('${s.$2}',
                                      style: GoogleFonts.dmSans(
                                          color: s.$3,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                  Text(s.$1.split(' ').first,
                                      style: GoogleFonts.dmSans(
                                          color: AppColors.textTertiary,
                                          fontSize: 9),
                                      textAlign: TextAlign.center),
                                ])))))
                    .toList()),
            const SizedBox(height: 14),

            // Recommendations
            if (recs.isNotEmpty)
              ACard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Icon(Icons.lightbulb_rounded,
                          color: AppColors.amber, size: 15),
                      const SizedBox(width: 7),
                      Text(t('aiRecommendations'),
                          style: GoogleFonts.dmSans(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 12),
                    ...recs.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                      color: AppColors.amberLight,
                                      shape: BoxShape.circle),
                                  child: Center(
                                      child: Text('${e.key + 1}',
                                          style: GoogleFonts.dmSans(
                                              color: AppColors.amber,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700)))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(e.value,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.5))),
                            ]))),
                  ])),

            const SizedBox(height: 20),
            Btn(
                label: t('updateFarmData'),
                icon: Icons.edit_rounded,
                onTap: () =>
                    Navigator.pushReplacementNamed(context, Routes.farmInput)),
          ])),
        ),
      ]),
    );
  }
}
