import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/ai_case_chat_args.dart';
import '../../routes/app_routes.dart';
import '../../services/language_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class ResidueIncomeScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ResidueIncomeScreen({super.key, required this.data});

  String t(String key) => LangSvc().t(key);

  Map<String, double> get _opts {
    final raw = data['all_options'] as Map?;
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }

  String get _best => data['best_option'] as String? ?? '';
  double get _earn => (data['projected_earnings'] as num? ?? 0).toDouble();

  void _openAiChat(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.aiCaseChat,
      arguments: AiCaseChatArgs(
        module: 'residue',
        title: _best.isEmpty ? t('incomeAnalysisTitle') : _best,
        imagePath: data['image_url'] as String?,
        context: data,
      ),
    );
  }

  Future<void> _speakSummary(BuildContext context) async {
    final summary = [
      if (_best.isNotEmpty) '${t('bestIncomeOption')}: $_best.',
      if (_earn > 0) '${t('projectedEarnings')}: ${H.rupees(_earn)}.',
      if ((data['description'] as String?)?.trim().isNotEmpty == true)
        (data['description'] as String).trim(),
    ].join(' ');
    if (summary.trim().isEmpty) return;
    await VoiceSvc().setLang(LangSvc().lang);
    await VoiceSvc().speak(summary);
    if (context.mounted) {
      H.snack(context, t('voiceProcessed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _opts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(t('incomeAnalysisTitle')),
          backgroundColor: AppColors.surface),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero earning
              Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.purpleDark,
                            const Color(0xFF7B1FA2)
                          ]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.purpleDark.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 6))
                      ]),
                  child: Column(children: [
                    Text(t('bestIncomeOption'),
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text(_best,
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(H.rupees(_earn),
                            style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1))),
                    const SizedBox(height: 8),
                    Text(
                        '${t('perLabel')} ${data['estimated_quantity_kg'] != null ? '${data['estimated_quantity_kg']}kg' : t('cropLabel').toLowerCase()} ${t('ofLabel')} ${data['residue_type']}',
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12)),
                  ])),
              const SizedBox(height: 22),

              Text(t('compareAllOptions'),
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              // Bar chart (manual)
              if (sorted.isNotEmpty) ...[
                ACard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...sorted.map((e) {
                            final isBest = e.key == _best;
                            final pct =
                                (e.value / sorted.first.value).clamp(0.0, 1.0);
                            return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            child: Text(e.key,
                                                style: GoogleFonts.dmSans(
                                                    fontSize: 13,
                                                    fontWeight: isBest
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    color: isBest
                                                        ? AppColors.purpleDark
                                                        : AppColors
                                                            .textSecondary))),
                                        if (isBest)
                                          Container(
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: AppColors.purpleDark,
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              child: Text(t('bestBadge'),
                                                  style: GoogleFonts.dmSans(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w800))),
                                        Text(H.rupees(e.value),
                                            style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isBest
                                                    ? AppColors.purpleDark
                                                    : AppColors.textSecondary)),
                                      ]),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0, end: pct),
                                              duration: const Duration(
                                                  milliseconds: 900),
                                              curve: Curves.easeOutCubic,
                                              builder: (_, v, __) =>
                                                  LinearProgressIndicator(
                                                      value: v,
                                                      minHeight: 10,
                                                      backgroundColor: AppColors
                                                          .purpleDark
                                                          .withValues(
                                                              alpha: 0.1),
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                              isBest
                                                                  ? AppColors
                                                                      .purpleDark
                                                                  : AppColors
                                                                      .border)))),
                                    ]));
                          }),
                        ])),
                const SizedBox(height: 14),
              ],

              // Description
              if (data['description'] != null)
                ACard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        const Icon(Icons.lightbulb_rounded,
                            color: AppColors.purpleDark, size: 15),
                        const SizedBox(width: 7),
                        Text(t('whyThisOption'),
                            style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      Text(data['description'] as String,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6)),
                      const SizedBox(height: 12),
                      Btn.outline(
                          label: t('speakAdvice'),
                          icon: Icons.volume_up_rounded,
                          fg: AppColors.purpleDark,
                          onTap: () => _speakSummary(context)),
                    ])),

              const SizedBox(height: 20),
              Btn.outline(
                  label: t('betterSuggestion'),
                  icon: Icons.chat_bubble_rounded,
                  fg: AppColors.purpleDark,
                  onTap: () => _openAiChat(context)),
              const SizedBox(height: 10),
              Btn(
                  label: t('findBuyersNearMe'),
                  icon: Icons.location_on_rounded,
                  bg: AppColors.purpleDark,
                  onTap: () => Navigator.pushNamed(context, Routes.svcSearch)),
              const SizedBox(height: 10),
              Btn.outline(
                  label: t('scanAgain'),
                  icon: Icons.refresh_rounded,
                  fg: AppColors.purpleDark,
                  onTap: () => Navigator.pushReplacementNamed(
                      context, Routes.residueScan)),
              const SizedBox(height: 20),
            ],
          )),
    );
  }
}
