import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/ai_case_chat_args.dart';
import '../../routes/app_routes.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class CropResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const CropResultScreen({super.key, required this.data});

  bool get _isCropDetection =>
      (data['analysis_mode'] as String? ?? '') == 'crop_detection';
  bool get _healthy =>
      (data['disease_name'] as String? ?? '').toLowerCase().contains('healthy');
  double get _conf => (data['confidence'] as num? ?? 0).toDouble();
  String get _severity => data['severity'] as String? ?? 'medium';
  String tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }
  Color get _color => _isCropDetection
      ? AppColors.cropGreen
      : (_healthy ? AppColors.success : H.riskColor(_severity));

  void _openAiChat(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.aiCaseChat,
      arguments: AiCaseChatArgs(
        module: _isCropDetection ? 'crop_detection' : 'crop',
        title: data['disease_name'] as String? ??
            tr('unknownLabel', 'Unknown'),
        imagePath: data['image_url'] as String?,
        context: data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: _color,
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
                    colors: [_color, _color.withValues(alpha: 0.85)],
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
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isCropDetection
                              ? Icons.spa_rounded
                              : (_healthy
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_amber_rounded),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isCropDetection
                            ? tr('cropDetectedBanner', 'CROP DETECTED')
                            : (_healthy
                                ? tr('healthyBanner', 'HEALTHY')
                                : tr('diseaseDetectedBanner', 'DISEASE DETECTED')),
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          data['disease_name'] as String? ?? tr('unknownLabel', 'Unknown'),
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          tr('confidence', 'Confidence'),
                          '${_conf.toStringAsFixed(1)}%',
                          Icons.analytics_rounded,
                          AppColors.info,
                          AppColors.infoFaint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metric(
                          _isCropDetection ? tr('resultLabel', 'Result') : tr('severityLabel', 'Severity'),
                          _isCropDetection ? tr('detectedLabel', 'Detected') : H.cap(_severity),
                          _isCropDetection
                              ? Icons.spa_rounded
                              : Icons.warning_amber_rounded,
                          _color,
                          _color.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metric(
                          tr('statusLabel', 'Status'),
                          _isCropDetection
                              ? tr('statusReady', 'Ready')
                              : (_healthy ? tr('statusClear', 'Clear') : tr('statusActNow', 'Act Now')),
                          _isCropDetection
                              ? Icons.check_circle_rounded
                              : (_healthy
                                  ? Icons.verified_rounded
                                  : Icons.priority_high_rounded),
                          _color,
                          _color.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ACard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sHead(
                          _isCropDetection
                              ? tr('aboutThisCrop', 'About this crop')
                              : tr('aboutThisCondition', 'About this condition'),
                          Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data['description'] as String? ?? '',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((data['recommended_fertilizer'] as String?)?.isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 12),
                    ACard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sHead(
                              tr('recommendedFertilizer', 'Recommended Fertilizer'), Icons.science_rounded),
                          const SizedBox(height: 10),
                          Text(
                            data['recommended_fertilizer'] as String? ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          if ((data['fertilizer_confidence'] as num?) !=
                              null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${tr('confidence', 'Confidence')} ${(data['fertilizer_confidence'] as num).toStringAsFixed(1)}%',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if ((data['fertilizer_tip'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 8),
                            Text(
                              data['fertilizer_tip'] as String,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if ((data['advisory'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.amber.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sHead(
                              tr('aiFieldAdvisory', 'AI Field Advisory'), Icons.auto_awesome_rounded),
                          const SizedBox(height: 10),
                          Text(
                            data['advisory'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!_healthy && !_isCropDetection) ...[
                    const SizedBox(height: 12),
                    if ((data['symptoms'] as List?)?.isNotEmpty == true)
                      ACard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sHead(tr('symptomsIdentified', 'Symptoms Identified'), Icons.search_rounded),
                            const SizedBox(height: 10),
                            ...(data['symptoms'] as List).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: _color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        s.toString(),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sHead(
                              tr('treatmentPlan', 'Treatment Plan'), Icons.medical_services_rounded),
                          const SizedBox(height: 10),
                          Text(
                            data['treatment_plan'] as String? ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ACard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sHead(tr('costVsLossAnalysis', 'Cost vs Loss Analysis'),
                              Icons.currency_rupee_rounded),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _costBox(
                                  tr('treatmentLabel', 'Treatment'),
                                  (data['treatment_cost'] as num? ?? 0)
                                      .toDouble(),
                                  AppColors.warning,
                                  AppColors.warningFaint,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _costBox(
                                  tr('ifUntreated', 'If Untreated'),
                                  (data['estimated_loss'] as num? ?? 0)
                                      .toDouble(),
                                  AppColors.danger,
                                  AppColors.dangerFaint,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _costBox(
                                  tr('youSave', 'You Save'),
                                  ((data['estimated_loss'] as num? ?? 0) -
                                          (data['treatment_cost'] as num? ?? 0))
                                      .toDouble()
                                      .clamp(0, double.infinity),
                                  AppColors.success,
                                  AppColors.successFaint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (data['source'] == 'offline') ...[
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
                              _isCropDetection
                                  ? tr('offlineCropDetectionResult',
                                      'Offline crop detection - connect for enhanced cloud results')
                                  : tr('offlineDiagnosisResult',
                                      'Offline diagnosis - connect for enhanced cloud results'),
                              style: GoogleFonts.dmSans(
                                  color: AppColors.info, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Btn.outline(
                    label: tr('betterSuggestion', 'Ask AI for Better Suggestion'),
                    icon: Icons.chat_bubble_rounded,
                    fg: _color,
                    onTap: () => _openAiChat(context),
                  ),
                  const SizedBox(height: 10),
                  Btn(
                    label: _isCropDetection
                        ? tr('detectAnotherCrop', 'Detect Another Crop')
                        : tr('scanAnotherCrop', 'Scan Another Crop'),
                    icon: Icons.camera_alt_rounded,
                    bg: _color,
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      _isCropDetection
                          ? Routes.cropDetectScan
                          : Routes.cropDiseaseScan,
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
      String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w800, color: color),
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

  Widget _sHead(String t, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 15),
        const SizedBox(width: 7),
        Text(
          t,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _costBox(String label, double amount, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(
            H.compact(amount),
            style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 3),
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
}
