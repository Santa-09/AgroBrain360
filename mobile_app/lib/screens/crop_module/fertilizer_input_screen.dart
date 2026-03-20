import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/fertilizer_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/language_service.dart';
import '../../services/tflite_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';

class FertilizerInputScreen extends StatefulWidget {
  const FertilizerInputScreen({super.key});

  @override
  State<FertilizerInputScreen> createState() => _FertilizerInputScreenState();
}

class _FertilizerInputScreenState extends State<FertilizerInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureCtrl = TextEditingController(text: '26');
  final _humidityCtrl = TextEditingController(text: '52');
  final _moistureCtrl = TextEditingController(text: '38');
  final _soilTypeCtrl = TextEditingController(text: 'Sandy');
  final _cropTypeCtrl = TextEditingController(text: 'Maize');
  final _nitrogenCtrl = TextEditingController(text: '37');
  final _potassiumCtrl = TextEditingController(text: '0');
  final _phosphorousCtrl = TextEditingController(text: '0');
  bool _busy = false;

  String t(String key) => LangSvc().t(key);

  @override
  void dispose() {
    _temperatureCtrl.dispose();
    _humidityCtrl.dispose();
    _moistureCtrl.dispose();
    _soilTypeCtrl.dispose();
    _cropTypeCtrl.dispose();
    _nitrogenCtrl.dispose();
    _potassiumCtrl.dispose();
    _phosphorousCtrl.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final payload = {
        'temperature': double.parse(_temperatureCtrl.text.trim()),
        'humidity': double.parse(_humidityCtrl.text.trim()),
        'moisture': double.parse(_moistureCtrl.text.trim()),
        'soil_type': _soilTypeCtrl.text.trim(),
        'crop_type': _cropTypeCtrl.text.trim(),
        'nitrogen': double.parse(_nitrogenCtrl.text.trim()),
        'potassium': double.parse(_potassiumCtrl.text.trim()),
        'phosphorous': double.parse(_phosphorousCtrl.text.trim()),
      };

      final online = await ConnSvc().check();
      Map<String, dynamic> responsePayload;
      if (online) {
        final response = await ApiSvc().post(ApiK.fertilizerPredict, payload);
        if (response.ok && response.data != null) {
          responsePayload = response.data!;
        } else {
          responsePayload = await TFSvc().predictFertilizer(
            temperature: payload['temperature'] as double,
            humidity: payload['humidity'] as double,
            moisture: payload['moisture'] as double,
            soilType: payload['soil_type'] as String,
            cropType: payload['crop_type'] as String,
            nitrogen: payload['nitrogen'] as double,
            potassium: payload['potassium'] as double,
            phosphorous: payload['phosphorous'] as double,
          );
        }
      } else {
        responsePayload = await TFSvc().predictFertilizer(
          temperature: payload['temperature'] as double,
          humidity: payload['humidity'] as double,
          moisture: payload['moisture'] as double,
          soilType: payload['soil_type'] as String,
          cropType: payload['crop_type'] as String,
          nitrogen: payload['nitrogen'] as double,
          potassium: payload['potassium'] as double,
          phosphorous: payload['phosphorous'] as double,
        );
      }

      if (!mounted) return;
      final result = FertilizerRecommendation.fromJson(responsePayload);
      Navigator.pushNamed(
        context,
        Routes.fertilizerResult,
        arguments: result,
      );
    } catch (e) {
      if (!mounted) return;
      H.snack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return t('requiredField');
    if (double.tryParse(value.trim()) == null) return t('enterValidNumber');
    return null;
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return t('requiredField');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('fertilizerRecommendation')),
        backgroundColor: AppColors.surface,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('fertilizerRecommendationIntro'),
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('fertilizerRecommendationHelper'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ACard(
                    child: Column(
                      children: [
                        _field(_temperatureCtrl, t('temperature'),
                            validator: _requiredNumber),
                        const SizedBox(height: 12),
                        _field(_humidityCtrl, t('humidity'),
                            validator: _requiredNumber),
                        const SizedBox(height: 12),
                        _field(_moistureCtrl, t('moisture'),
                            validator: _requiredNumber),
                        const SizedBox(height: 12),
                        _field(_soilTypeCtrl, t('soilType'),
                            validator: _requiredText),
                        const SizedBox(height: 12),
                        _field(_cropTypeCtrl, t('cropType'),
                            validator: _requiredText),
                        const SizedBox(height: 12),
                        _field(_nitrogenCtrl, t('nitrogen'),
                            validator: _requiredNumber),
                        const SizedBox(height: 12),
                        _field(_potassiumCtrl, t('potassium'),
                            validator: _requiredNumber),
                        const SizedBox(height: 12),
                        _field(_phosphorousCtrl, t('phosphorous'),
                            validator: _requiredNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Btn(
                    label: t('predictFertilizer'),
                    icon: Icons.science_rounded,
                    bg: AppColors.primary,
                    onTap: _busy ? null : _predict,
                    loading: _busy,
                  ),
                ],
              ),
            ),
          ),
          if (_busy) LoadingOverlay(msg: t('predictingFertilizer')),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
    );
  }
}
