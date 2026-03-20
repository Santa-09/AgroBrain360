import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/language_service.dart';
import '../../services/local_db_service.dart';
import '../../widgets/custom_button.dart';

class FarmInputScreen extends StatefulWidget {
  const FarmInputScreen({super.key});

  @override
  State<FarmInputScreen> createState() => _FarmInputScreenState();
}

class _FarmInputScreenState extends State<FarmInputScreen> {
  bool _busy = false;
  double _crop = 60;
  double _soil = 55;
  double _water = 50;
  double _livestock = 65;
  double _machinery = 70;

  String t(String key) => LangSvc().t(key);

  int get _fhi => ((_crop * 0.35) +
          (_soil * 0.25) +
          (_water * 0.20) +
          (_livestock * 0.10) +
          (_machinery * 0.10))
      .round();

  Future<void> _calculate() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      Map<String, dynamic> result;
      final online = await ConnSvc().check();
      final body = {
        'crop_score': _crop.round(),
        'soil_score': _soil.round(),
        'water_score': _water.round(),
        'livestock_score': _livestock.round(),
        'machinery_score': _machinery.round(),
      };
      if (online) {
        final r = await ApiSvc().post(ApiK.fhi, body);
        result = (r.ok && r.data != null) ? r.data! : _local();
      } else {
        result = _local();
      }
      await DB.saveFHI(result);
      if (!mounted) return;
      Navigator.pushNamed(context, Routes.healthScore, arguments: result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _local() {
    final score = _fhi;
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'overall_score': score,
      'label': H.fhiLabel(score),
      'crop_score': _crop.round(),
      'soil_score': _soil.round(),
      'water_score': _water.round(),
      'livestock_score': _livestock.round(),
      'machinery_score': _machinery.round(),
      'recommendations': [
        if (_crop < 60) 'Improve crop care: schedule weekly disease scans',
        if (_soil < 60) 'Test soil pH and apply lime or fertilizer accordingly',
        if (_water < 60) 'Upgrade irrigation: drip system can save 40% water',
        if (_livestock < 60)
          'Livestock health check overdue - schedule vet visit',
        if (_machinery < 60) 'Service farm equipment before next season',
        if (_fhi >= 60) 'Farm is doing well! Maintain current practices.',
      ].take(4).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = H.fhiColor(_fhi);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('farmInput')),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryMid],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_fhi',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('farmHealth'),
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          H.fhiLabel(_fhi),
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _fhi / 100,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _slider('${t('cropCondition')} (35%)', Icons.grass_rounded,
                AppColors.cropGreen, _crop, (v) => setState(() => _crop = v)),
            _slider('${t('soilHealth')} (25%)', Icons.terrain_rounded,
                const Color(0xFF795548), _soil, (v) => setState(() => _soil = v)),
            _slider('${t('waterAccess')} (20%)', Icons.water_drop_rounded,
                AppColors.info, _water, (v) => setState(() => _water = v)),
            _slider('${t('livestockStatus')} (10%)', Icons.pets_rounded,
                AppColors.tealDark, _livestock, (v) => setState(() => _livestock = v)),
            _slider('${t('machineryStatus')} (10%)', Icons.agriculture_rounded,
                AppColors.orangeDark, _machinery, (v) => setState(() => _machinery = v)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t('rateEachCategory'),
                      style: GoogleFonts.dmSans(
                        color: AppColors.primary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Btn(
              label: t('calculateFHI'),
              icon: Icons.monitor_heart_rounded,
              onTap: _calculate,
              loading: _busy,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    IconData icon,
    Color color,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.12),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
          Row(
            children: [
              Text(
                '${t('zeroLabel')} - ${t('critical')}',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              Text(
                '${t('hundredLabel')} - ${t('excellent')}',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
