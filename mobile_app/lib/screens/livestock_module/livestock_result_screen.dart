import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/ai_case_chat_args.dart';
import '../../routes/app_routes.dart';
import '../../services/language_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class LivestockResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const LivestockResultScreen({super.key, required this.data});

  String t(String key) => LangSvc().t(key);

  String get _risk => data['health_risk'] as String? ?? 'medium';
  Color get _color => H.riskColor(_risk);
  int get _pct => (((data['risk_probability'] as num?) ?? 0) * 100).round();

  void _openAiChat(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.aiCaseChat,
      arguments: AiCaseChatArgs(
        module: 'livestock',
        title: data['diagnosis'] as String? ?? t('diagnosisComplete'),
        imagePath: data['image_url'] as String?,
        context: data,
      ),
    );
  }

  Future<void> _speakAdvice(BuildContext context, String text) async {
    final clean = text.replaceAll('**', '').trim();
    if (clean.isEmpty) return;
    await VoiceSvc().setLang(LangSvc().lang);
    await VoiceSvc().speak(clean);
    if (context.mounted) {
      H.snack(context, t('voiceProcessed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = List<String>.from(data['medicines'] ?? []);
    final steps = _parseSteps(data['first_aid_protocol'] as String? ?? '');
    final advisory = (data['advisory'] as String?)?.replaceAll('**', '');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200,
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_color, _color.withValues(alpha: 0.75)])),
              child: SafeArea(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const SizedBox(height: 36),
                    Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.pets_rounded,
                            color: Colors.white, size: 28)),
                    const SizedBox(height: 8),
                    Text(data['animal_type'] as String? ?? '',
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            letterSpacing: 1)),
                    const SizedBox(height: 3),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                            data['diagnosis'] as String? ??
                                t('diagnosisComplete'),
                            style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center)),
                  ])),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            // Risk banner
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _color.withValues(alpha: 0.25))),
                child: Row(children: [
                  Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: Icon(Icons.health_and_safety_rounded,
                          color: _color, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(t('healthRiskLevel'),
                            style: GoogleFonts.dmSans(
                                color: AppColors.textTertiary, fontSize: 11)),
                        Text('${H.cap(_risk)} Risk — $_pct% probability',
                            style: GoogleFonts.dmSans(
                                color: _color,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ])),
                ])),
            const SizedBox(height: 12),

            // First Aid
            ACard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _head(t('firstAidProtocol'), Icons.medical_services_rounded),
                  const SizedBox(height: 12),
                  ...steps
                      .asMap()
                      .entries
                      .map((e) => _step(e.key + 1, e.value)),
                ])),
            const SizedBox(height: 12),

            if (advisory != null && advisory.trim().isNotEmpty) ...[
              ACard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _head(t('aiAdvisory'), Icons.psychology_rounded),
                    const SizedBox(height: 12),
                    Text(advisory,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6)),
                    const SizedBox(height: 12),
                    Btn.outline(
                        label: t('speakAdvice'),
                        icon: Icons.volume_up_rounded,
                        fg: AppColors.tealDark,
                        onTap: () => _speakAdvice(context, advisory)),
                  ])),
              const SizedBox(height: 12),
            ],

            // Medicines
            if (meds.isNotEmpty) ...[
              ACard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _head(t('recommendedMedicines'), Icons.medication_rounded),
                    const SizedBox(height: 12),
                    ...meds.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                                color: AppColors.tealFaint,
                                borderRadius: BorderRadius.circular(9)),
                            child: Row(children: [
                              const Icon(Icons.local_pharmacy_rounded,
                                  color: AppColors.tealDark, size: 15),
                              const SizedBox(width: 9),
                              Expanded(
                                  child: Text(m,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: AppColors.textSecondary))),
                            ])))),
                  ])),
              const SizedBox(height: 12),
            ],

            // Vet CTA
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.tealDark.withValues(alpha: 0.92),
                      AppColors.tealDark
                    ]),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('nearestVeterinarian'),
                          style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(
                          data['nearest_vet_name'] as String? ??
                              t('veterinaryClinic'),
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          H.dist(((data['nearest_vet_distance'] as num?) ?? 0)
                                      .toDouble() *
                                  1000) +
                              ' away',
                          style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12)),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: _vetBtn(t('callNow'), Icons.phone_rounded,
                                Colors.white, AppColors.tealDark, () {
                          final p = data['nearest_vet_phone'] as String?;
                          if (p != null) launchUrl(Uri.parse('tel:$p'));
                        })),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _vetBtn(
                                t('whatsappLabel'),
                                Icons.chat_rounded,
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white, () {
                          final p = (data['nearest_vet_phone'] as String? ?? '')
                              .replaceAll(RegExp(r'\D'), '');
                          launchUrl(Uri.parse(
                              'https://wa.me/91$p?text=Hello+Doctor,+my+${data['animal_type']}+needs+attention.'));
                        }, border: true)),
                      ]),
                    ])),
            const SizedBox(height: 16),
            Btn.outline(
                label: t('betterSuggestion'),
                icon: Icons.chat_bubble_rounded,
                fg: AppColors.tealDark,
                onTap: () => _openAiChat(context)),
            const SizedBox(height: 10),
            Btn.outline(
                label: t('newDiagnosis'),
                icon: Icons.refresh_rounded,
                fg: AppColors.tealDark,
                onTap: () => Navigator.pushReplacementNamed(
                    context, Routes.livestockIn)),
          ])),
        ),
      ]),
    );
  }

  Widget _head(String t, IconData icon) => Row(children: [
        Icon(icon, color: AppColors.primary, size: 15),
        const SizedBox(width: 8),
        Text(t,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ]);

  Widget _step(int n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: AppColors.tealFaint, shape: BoxShape.circle),
            child: Center(
                child: Text('$n',
                    style: GoogleFonts.dmSans(
                        color: AppColors.tealDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)))),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5))),
      ]));

  Widget _vetBtn(
          String label, IconData icon, Color bg, Color fg, VoidCallback onTap,
          {bool border = false}) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: border
                      ? Border.all(color: Colors.white.withValues(alpha: 0.4))
                      : null),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: fg, size: 15),
                const SizedBox(width: 6),
                Text(label,
                    style: GoogleFonts.dmSans(
                        color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
              ])));

  List<String> _parseSteps(String s) => s.contains('\n')
      ? s
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
          .toList()
      : [s];
}
