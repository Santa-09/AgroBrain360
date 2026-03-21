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
import '../../services/tflite_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final _nitrogenCtrl = TextEditingController(text: '90');
  final _phosphorousCtrl = TextEditingController(text: '42');
  final _potassiumCtrl = TextEditingController(text: '43');
  final _temperatureCtrl = TextEditingController(text: '20.8');
  final _humidityCtrl = TextEditingController(text: '82.0');
  final _phCtrl = TextEditingController(text: '6.5');
  final _rainfallCtrl = TextEditingController(text: '202.9');
  bool _busy = false;

  String t(String key) => LangSvc().t(key);

  @override
  void dispose() {
    _nitrogenCtrl.dispose();
    _phosphorousCtrl.dispose();
    _potassiumCtrl.dispose();
    _temperatureCtrl.dispose();
    _humidityCtrl.dispose();
    _phCtrl.dispose();
    _rainfallCtrl.dispose();
    super.dispose();
  }

  Future<void> _recommend() async {
    setState(() => _busy = true);
    try {
      final payload = {
        'nitrogen': double.parse(_nitrogenCtrl.text.trim()),
        'phosphorous': double.parse(_phosphorousCtrl.text.trim()),
        'potassium': double.parse(_potassiumCtrl.text.trim()),
        'temperature': double.parse(_temperatureCtrl.text.trim()),
        'humidity': double.parse(_humidityCtrl.text.trim()),
        'ph': double.parse(_phCtrl.text.trim()),
        'rainfall': double.parse(_rainfallCtrl.text.trim()),
      };

      final online = await ConnSvc().check();
      Map<String, dynamic> result;
      bool usedCloud = false;
      if (online) {
        final response = await ApiSvc().post(ApiK.cropRecommend, payload);
        if (response.ok && response.data != null) {
          result = response.data!['data'] as Map<String, dynamic>? ??
              response.data!;
          usedCloud = true;
        } else {
          result = await TFSvc().predictCropRecommendation(
            nitrogen: payload['nitrogen'] as double,
            phosphorous: payload['phosphorous'] as double,
            potassium: payload['potassium'] as double,
            temperature: payload['temperature'] as double,
            humidity: payload['humidity'] as double,
            ph: payload['ph'] as double,
            rainfall: payload['rainfall'] as double,
          );
        }
      } else {
        result = await TFSvc().predictCropRecommendation(
          nitrogen: payload['nitrogen'] as double,
          phosphorous: payload['phosphorous'] as double,
          potassium: payload['potassium'] as double,
          temperature: payload['temperature'] as double,
          humidity: payload['humidity'] as double,
          ph: payload['ph'] as double,
          rainfall: payload['rainfall'] as double,
        );
      }

      result = {
        ...result,
        'source': usedCloud ? 'cloud' : 'offline',
      };

      await DB.saveScan(
        DateTime.now().millisecondsSinceEpoch.toString(),
        {
          'type': 'crop',
          'title': H.displayText(result['crop']?.toString() ?? t('unknownLabel')),
          'result': t('recommendedLabel'),
          'ts': DateTime.now().toIso8601String(),
          'source': result['source'],
        },
      );

      if (result['source'] == 'offline') {
        await DB.addSyncRecord(
          module: 'crop_recommendation',
          payload: {
            ...payload,
            'crop': result['crop'],
            'confidence': result['confidence'],
          },
        );
      }

      if (!mounted) return;
      Navigator.pushNamed(context, Routes.cropRecommendationResult,
          arguments: result);
    } catch (e) {
      if (!mounted) return;
      H.snack(context, '${t('recommendationFailed')}: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('cropRecommendation')),
        backgroundColor: AppColors.surface,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('cropRecommendationIntro'),
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ACard(
                  child: Column(
                    children: [
                      _field(_nitrogenCtrl, t('nitrogen')),
                      const SizedBox(height: 10),
                      _field(_phosphorousCtrl, t('phosphorous')),
                      const SizedBox(height: 10),
                      _field(_potassiumCtrl, t('potassium')),
                      const SizedBox(height: 10),
                      _field(_temperatureCtrl, t('temperature')),
                      const SizedBox(height: 10),
                      _field(_humidityCtrl, t('humidity')),
                      const SizedBox(height: 10),
                      _field(_phCtrl, t('phLabel')),
                      const SizedBox(height: 10),
                      _field(_rainfallCtrl, t('rainfall')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Btn(
                  label: t('recommendCrop'),
                  icon: Icons.spa_rounded,
                  bg: AppColors.cropGreen,
                  onTap: _busy ? null : _recommend,
                  loading: _busy,
                ),
              ],
            ),
          ),
          if (_busy) LoadingOverlay(msg: t('recommendingCrop')),
        ],
      ),
    );
  }
}
