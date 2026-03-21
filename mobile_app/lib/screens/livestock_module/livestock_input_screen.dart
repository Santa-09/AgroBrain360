import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/image_validation_service.dart';
import '../../services/language_service.dart';
import '../../services/local_db_service.dart';
import '../../services/tflite_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class LivestockInputScreen extends StatefulWidget {
  const LivestockInputScreen({super.key});

  @override
  State<LivestockInputScreen> createState() => _LivestockInputScreenState();
}

class _LivestockInputScreenState extends State<LivestockInputScreen> {
  final _sympCtrl = TextEditingController();
  File? _img;
  String _animal = 'Cow';
  bool _busy = false;
  bool _listening = false;
  bool _backendRecording = false;
  final _picker = ImagePicker();

  static const _animals = [
    'Cow',
    'Buffalo',
    'Goat',
    'Sheep',
    'Pig',
    'Chicken',
    'Horse',
    'Fish',
  ];

  String t(String key) => LangSvc().t(key);

  @override
  void dispose() {
    unawaited(VoiceSvc().stop());
    unawaited(VoiceSvc().cancelBackendRecording());
    _sympCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImg() async {
    final f = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (f != null && mounted) {
      setState(() => _img = File(f.path));
    }
  }

  Future<void> _toggleVoice() async {
    if (_backendRecording) {
      setState(() => _busy = true);
      final res = await VoiceSvc().stopBackendRecordingAndTranscribe(
        lang: LangSvc().lang,
        detectIntent: false,
        prompt: 'Animal type: $_animal. Transcribe the farmer symptoms clearly.',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _backendRecording = false;
      });
      if (res.ok && res.data != null) {
        final payload = res.data!;
        final data = payload['data'] as Map<String, dynamic>? ?? payload;
        final text = (data['text'] ?? '').toString().trim();
        if (text.isNotEmpty) {
          setState(() => _sympCtrl.text = text);
        } else {
          H.snack(context, t('noSpeechDetected'), error: true);
        }
      } else {
        H.snack(context, res.error ?? t('voiceFailed'), error: true);
      }
      return;
    }
    if (_listening) {
      await VoiceSvc().stop();
      setState(() => _listening = false);
      return;
    }

    setState(() => _listening = true);
    final started = await VoiceSvc().listen(
      onResult: (text) {
        setState(() {
          _sympCtrl.text = text;
          _listening = false;
        });
      },
      lang: LangSvc().lang,
    );
    if (!started && mounted) {
      setState(() => _listening = false);
      final backendStarted = await VoiceSvc().startBackendRecording();
      if (!mounted) return;
      if (backendStarted) {
        setState(() => _backendRecording = true);
        H.snack(context, t('recordingAiVoice'));
      } else {
        H.snack(context, t('voiceUnavailable'), error: true);
      }
    }
  }

  Future<void> _toggleWhisper() async {
    if (_backendRecording) {
      setState(() => _busy = true);
      final res = await VoiceSvc().stopBackendRecordingAndProcessVoice(
        module: 'livestock',
        context: {
          'animal_type': _animal,
          'symptoms': _sympCtrl.text.trim(),
        },
        lang: LangSvc().lang,
        detectIntent: true,
        prompt:
            'Animal type: $_animal. Transcribe the farmer symptoms clearly.',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _backendRecording = false;
      });

      if (res.ok && res.data != null) {
        final payload = res.data!;
        final data = payload['data'] as Map<String, dynamic>? ?? payload;
        final text = (data['user_text'] ?? '').toString().trim();
        if (text.isNotEmpty) {
          setState(() => _sympCtrl.text = text);
          await VoiceSvc().setLang(LangSvc().lang);
          await VoiceSvc().speakWithFallback(
            audioUrl: data['audio_url']?.toString(),
            fallbackText: (data['ai_response'] ?? '').toString(),
          );
          H.snack(context, t('voiceProcessed'));
        } else {
          H.snack(context, t('noSpeechDetected'), error: true);
        }
      } else {
        H.snack(context, res.error ?? t('voiceFailed'), error: true);
      }
      return;
    }

    if (_listening) {
      await VoiceSvc().stop();
      if (mounted) setState(() => _listening = false);
    }
    final started = await VoiceSvc().startBackendRecording();
    if (!mounted) return;
    if (!started) {
      H.snack(context, t('whisperNeedsInternet'), error: true);
      return;
    }
    setState(() => _backendRecording = true);
  }

  Future<void> _diagnose() async {
    if (_sympCtrl.text.trim().isEmpty) {
      H.snack(context, t('pleaseDescribeSymptoms'), error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      if (_img != null) {
        final validation =
            await ImageValidationSvc().validateLivestockDiseaseImage(_img!);
        if (!validation.valid) {
          if (mounted) {
            H.snack(
              context,
              t('recaptureDiseaseInput'),
              error: true,
            );
          }
          return;
        }
      }

      final online = await ConnSvc().check();
      Map<String, dynamic> result;
      if (online) {
        final response = await ApiSvc().post(ApiK.livestock, {
          'animal_type': _animal,
          'symptoms': _sympCtrl.text.trim(),
          'language': LangSvc().lang,
        });
        result = (response.ok && response.data != null)
            ? await _buildOnlineResult(response.data!)
            : await _offline();
      } else {
        result = await _offline();
        await DB.addSyncRecord(
          module: 'livestock',
          payload: {
            'animal_type': _animal,
            'symptoms': _sympCtrl.text.trim(),
            'disease': result['diagnosis'],
            'risk_level': result['health_risk'],
            'treatment': result['treatment'] ?? result['first_aid_protocol'],
          },
        );
      }

      await DB.saveScan(DateTime.now().millisecondsSinceEpoch.toString(), {
        'type': 'livestock',
        'title':
            '${LangSvc().displayAnimal(_animal)} - ${_sympCtrl.text.trim().split(' ').take(3).join(' ')}...',
        'result': H.cap(result['health_risk'] ?? 'Diagnosed'),
        'ts': DateTime.now().toIso8601String(),
      });

      final spoken = (result['advisory'] as String?) ??
          (result['first_aid_protocol'] as String?) ??
          (result['treatment'] as String?);
      if (spoken != null && spoken.trim().isNotEmpty) {
        await VoiceSvc().setLang(LangSvc().lang);
        await VoiceSvc().speak(spoken);
      }

      if (!mounted) return;
      Navigator.pushNamed(context, Routes.livestockRes, arguments: result);
    } catch (_) {
      if (mounted) H.snack(context, t('diagnosisFailed'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, dynamic>> _buildOnlineResult(
    Map<String, dynamic> response,
  ) async {
    final data = response['data'] as Map<String, dynamic>? ?? response;
    String? advisory;

    final llm = await ApiSvc().post(ApiK.llmAdvise, {
      'module': 'livestock',
      'data': {
        'animal_type': _animal,
        'symptoms': _sympCtrl.text.trim(),
        'disease_name': data['disease'] ?? 'Unknown',
        'risk_level': data['risk_level'] ?? 'medium',
        'treatment': data['treatment'] ?? '',
        'first_aid': data['first_aid'] ?? '',
        'language': LangSvc().lang,
      },
      'language': LangSvc().lang,
    });

    if (llm.ok && llm.data != null) {
      final llmPayload = llm.data!['data'] as Map<String, dynamic>? ?? llm.data!;
      advisory = llmPayload['advice']?.toString().replaceAll('**', '');
    }

    return {
      'animal_type': _animal,
      'symptoms': _sympCtrl.text.trim(),
      'diagnosis': data['disease'] ?? 'Unknown',
      'health_risk': (data['risk_level'] ?? 'medium').toString().toLowerCase(),
      'risk_probability': _riskProbabilityFromLevel(
        (data['risk_level'] ?? 'medium').toString(),
      ),
      'first_aid_protocol': data['first_aid'] ?? data['treatment'] ?? '',
      'treatment': data['treatment'] ?? '',
      'advisory': advisory,
      'medicines': <String>[],
      'nearest_vet_name': 'Dr. Ramesh Patel',
      'nearest_vet_phone': '9876543210',
      'nearest_vet_distance': 2.3,
      'diagnosed_at': DateTime.now().toIso8601String(),
      'source': 'cloud',
    };
  }

  double _riskProbabilityFromLevel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 0.85;
      case 'low':
        return 0.25;
      default:
        return 0.60;
    }
  }

  Map<String, dynamic> _mock() => {
        'animal_type': _animal,
        'symptoms': _sympCtrl.text,
        'diagnosis': 'Suspected Respiratory Infection (FMD risk)',
        'health_risk': 'medium',
        'risk_probability': 0.70,
        'first_aid_protocol':
            '1. Isolate the animal immediately from the herd.\n2. Ensure access to fresh water and good ventilation.\n3. Monitor body temperature every 4 hours.\n4. Withhold solid feed if respiratory distress is present.\n5. Contact a licensed veterinarian within 24 hours.',
        'medicines': [
          'Oxytetracycline 20mg/kg IM once daily',
          'Vitamin B Complex injection',
          'ORS in drinking water',
          'Anti-pyretic if fever > 40C',
        ],
        'nearest_vet_name': 'Dr. Ramesh Kumar - Govt. Veterinary Hospital',
        'nearest_vet_phone': '9876543210',
        'nearest_vet_distance': 3.2,
        'image_url': _img?.path ?? '',
        'diagnosed_at': DateTime.now().toIso8601String(),
      };

  Future<Map<String, dynamic>> _offline() async {
    if (_img != null) {
      final inference = await TFSvc().classifyLivestock(_img!);
      final label = (inference['label'] as String? ?? 'healthy').toLowerCase();
      final confidence = ((inference['confidence'] as num?) ?? 0).toDouble();
      final mapped = {
        'foot-and-mouth': {
          'diagnosis': 'Foot and Mouth Disease',
          'health_risk': 'high',
          'risk_probability': confidence,
          'first_aid_protocol':
              '1. Isolate the animal immediately.\n2. Keep feed soft and water clean.\n3. Clean mouth and feet gently with antiseptic.\n4. Contact a veterinarian urgently.',
        },
        'lumpy': {
          'diagnosis': 'Lumpy Skin Disease',
          'health_risk': 'medium',
          'risk_probability': confidence,
          'first_aid_protocol':
              '1. Isolate the animal from the herd.\n2. Reduce insect exposure.\n3. Keep wounds clean and monitor fever.\n4. Contact a veterinarian for treatment guidance.',
        },
        'healthy': {
          'diagnosis': 'Healthy',
          'health_risk': 'low',
          'risk_probability': confidence,
          'first_aid_protocol':
              'No urgent first aid needed. Continue clean water, balanced feed, and observation.',
        },
      }[label]!;

      return {
        'animal_type': _animal,
        'symptoms': _sympCtrl.text.trim(),
        'diagnosis': mapped['diagnosis'],
        'health_risk': mapped['health_risk'],
        'risk_probability': mapped['risk_probability'],
        'first_aid_protocol': mapped['first_aid_protocol'],
        'treatment': mapped['first_aid_protocol'],
        'medicines': <String>[],
        'nearest_vet_name': 'Nearest vet when online',
        'nearest_vet_phone': '9876543210',
        'nearest_vet_distance': 0.0,
        'image_url': _img?.path ?? '',
        'diagnosed_at': DateTime.now().toIso8601String(),
        'source': 'offline',
      };
    }

    return _offlineFromSymptoms();
  }

  Map<String, dynamic> _offlineFromSymptoms() {
    final text = _sympCtrl.text.toLowerCase();
    if (text.contains('blister') ||
        text.contains('drool') ||
        text.contains('hoof')) {
      return {
        ..._mock(),
        'diagnosis': 'Foot and Mouth Disease',
        'health_risk': 'high',
        'risk_probability': 0.82,
        'source': 'offline',
      };
    }
    if (text.contains('lump') || text.contains('skin nodule')) {
      return {
        ..._mock(),
        'diagnosis': 'Lumpy Skin Disease',
        'health_risk': 'medium',
        'risk_probability': 0.74,
        'source': 'offline',
      };
    }
    return {
      ..._mock(),
      'source': 'offline',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('livestockDiagnosisTitle')),
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
                  t('selectAnimal'),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _animals.length,
                    itemBuilder: (_, i) {
                      final selected = _animals[i] == _animal;
                      return GestureDetector(
                        onTap: () => setState(() => _animal = _animals[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.tealDark
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: selected
                                  ? AppColors.tealDark
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            LangSvc().displayAnimal(_animals[i]),
                            style: GoogleFonts.dmSans(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t('animalPhotoOptional'),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImg,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: _img == null ? AppColors.tealFaint : null,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _img == null
                            ? AppColors.tealDark.withValues(alpha: 0.35)
                            : Colors.transparent,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _img == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                color: AppColors.tealDark,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                t('tapToAddPhoto'),
                                style: GoogleFonts.dmSans(
                                  color: AppColors.tealDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Image.file(
                            _img!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('describeSymptoms'),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleVoice,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _listening
                              ? AppColors.danger
                              : AppColors.tealFaint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _listening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: _listening
                                  ? Colors.white
                                  : AppColors.tealDark,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _listening ? t('stop') : t('voice'),
                              style: GoogleFonts.dmSans(
                                color: _listening
                                    ? Colors.white
                                    : AppColors.tealDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleWhisper,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _backendRecording
                              ? AppColors.warning
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _backendRecording
                                ? AppColors.warning
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _backendRecording
                                  ? Icons.stop_circle_outlined
                                  : Icons.cloud_rounded,
                              color: _backendRecording
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _backendRecording ? t('stop') : t('aiVoice'),
                              style: GoogleFonts.dmSans(
                                color: _backendRecording
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _listening ? AppColors.danger : AppColors.border,
                    ),
                  ),
                  child: TextField(
                    controller: _sympCtrl,
                    maxLines: 5,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: t('livestockSymptomsHint'),
                      hintStyle: GoogleFonts.dmSans(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                if (_listening) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerFaint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mic_rounded,
                          color: AppColors.danger,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t('listeningSpeakClearly'),
                          style: GoogleFonts.dmSans(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_backendRecording) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningFaint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_rounded,
                          color: AppColors.warning,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('recordingAiVoice'),
                            style: GoogleFonts.dmSans(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Btn(
                  label: t('diagnoseNow'),
                  icon: Icons.medical_information_rounded,
                  bg: AppColors.tealDark,
                  onTap: _diagnose,
                  loading: _busy,
                ),
                const SizedBox(height: 16),
                _tip(),
              ],
            ),
          ),
          if (_busy) LoadingOverlay(msg: t('diagnosingWithAI')),
        ],
      ),
    );
  }

  Widget _tip() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.tealFaint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.tealDark.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.tealDark,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t('livestockTip'),
                style: GoogleFonts.dmSans(
                  color: AppColors.tealDark,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
}
