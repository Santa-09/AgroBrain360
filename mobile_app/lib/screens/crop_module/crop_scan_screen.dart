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

enum CropScanMode { diseaseDetection, cropDetection }

class CropScanScreen extends StatefulWidget {
  final CropScanMode mode;
  const CropScanScreen({
    super.key,
    this.mode = CropScanMode.diseaseDetection,
  });

  @override
  State<CropScanScreen> createState() => _CropScanScreenState();
}

class _CropScanScreenState extends State<CropScanScreen> {
  static final List<String> _diseasePlantOptions = TFSvc.diseasePlantNames;
  File? _img;
  bool _busy = false;
  bool _listening = false;
  bool _backendRecording = false;
  final _picker = ImagePicker();
  final _cropTypeCtrl = TextEditingController();
  final _areaCtrl = TextEditingController(text: '1.0');
  final _tempCtrl = TextEditingController();
  final _humidityCtrl = TextEditingController();
  final _moistureCtrl = TextEditingController();
  final _soilTypeCtrl = TextEditingController();
  final _nitrogenCtrl = TextEditingController();
  final _potassiumCtrl = TextEditingController();
  final _phosphorousCtrl = TextEditingController();
  bool _usedOfflineFallback = false;
  String? _selectedDiseasePlant;

  @override
  void dispose() {
    unawaited(VoiceSvc().stop());
    unawaited(VoiceSvc().cancelBackendRecording());
    _cropTypeCtrl.dispose();
    _areaCtrl.dispose();
    _tempCtrl.dispose();
    _humidityCtrl.dispose();
    _moistureCtrl.dispose();
    _soilTypeCtrl.dispose();
    _nitrogenCtrl.dispose();
    _potassiumCtrl.dispose();
    _phosphorousCtrl.dispose();
    super.dispose();
  }

  String get _screenTitle => widget.mode == CropScanMode.cropDetection
      ? _tr('cropDetectionTitle', 'Crop Detection')
      : _tr('cropDiseaseScanTitle', 'Crop Disease Scan');

  String get _detailsLabel => widget.mode == CropScanMode.cropDetection
      ? _tr('cropNotesOptional', 'Crop notes (optional)')
      : _tr('cropDetailsOptional', 'Crop details (optional)');

  String get _voiceHint => widget.mode == CropScanMode.cropDetection
      ? _tr('cropListeningNotes', 'Listening... say crop details clearly')
      : _tr('cropListeningType', 'Listening... say the crop type clearly');

  String get _whisperPrompt => widget.mode == CropScanMode.cropDetection
      ? 'Transcribe crop notes and crop identity clues clearly for a crop detection scan.'
      : 'Transcribe crop type and field notes clearly for a crop disease scan.';

  String get _heroTitle => widget.mode == CropScanMode.cropDetection
      ? _tr('cropHeroTitleDetection', 'Tap to photograph the crop plant')
      : _tr('cropHeroTitleDisease', 'Tap to photograph crop leaf');

  String get _heroSubtitle => widget.mode == CropScanMode.cropDetection
      ? _tr('cropHeroSubDetection', 'Capture the crop clearly for identification')
      : _tr('cropHeroSubDisease', 'Clear photo of the affected area works best');

  String get _analyzeLabel => widget.mode == CropScanMode.cropDetection
      ? _tr('detectCropWithAI', 'Detect Crop with AI')
      : _tr('analyzeWithAI', 'Analyze with AI');

  String _tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  String _displayPlantName(String value) => LangSvc().displayText(value);

  Future<void> _pick(ImageSource src) async {
    final f =
        await _picker.pickImage(source: src, imageQuality: 85, maxWidth: 1024);
    if (f != null) {
      if (mounted) setState(() => _img = File(f.path));
    }
  }

  String? _matchDiseasePlant(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final plant in _diseasePlantOptions) {
      if (plant.toLowerCase() == normalized) return plant;
    }
    for (final plant in _diseasePlantOptions) {
      if (plant.toLowerCase().contains(normalized) ||
          normalized.contains(plant.toLowerCase())) {
        return plant;
      }
    }
    return null;
  }

  void _setCropType(String value) {
    final text = value.trim();
    _cropTypeCtrl.text = text;
    if (widget.mode == CropScanMode.diseaseDetection) {
      _selectedDiseasePlant = _matchDiseasePlant(text);
    }
  }

  Future<void> _analyze() async {
    if (_img == null) return;
    setState(() => _busy = true);
    _usedOfflineFallback = false;
    try {
      if (widget.mode == CropScanMode.diseaseDetection) {
        final validation =
            await ImageValidationSvc().validateCropDiseaseImage(_img!);
        if (!validation.valid) {
          if (mounted) {
            H.snack(
              context,
              _tr(
                'recaptureDiseaseInput',
                ImageValidationSvc.rejectionMessage,
              ),
              error: true,
            );
          }
          return;
        }
      }

      Map<String, dynamic> result;
      final online = await ConnSvc().check();
      final cropType = _cropTypeCtrl.text.trim();
      final areaAcres = double.tryParse(_areaCtrl.text.trim()) ?? 1.0;

      if (online) {
        final r = await ApiSvc().multipart(ApiK.cropPredict, _img!, {
          if (cropType.isNotEmpty) 'crop_type': cropType,
          'area_acres': areaAcres.toString(),
          'lang': LangSvc().lang,
        });
        if (r.ok && r.data != null) {
          result = _normalizeOnline(r.data!);
        } else {
          _usedOfflineFallback = true;
          result = await _offline();
        }
      } else {
        _usedOfflineFallback = true;
        result = await _offline();
      }

      if (result['source'] != 'cloud') {
        await DB.addSyncRecord(
          module: widget.mode == CropScanMode.cropDetection
              ? 'crop_detection'
              : 'crop',
          payload: {
            'analysis_mode': widget.mode == CropScanMode.cropDetection
                ? 'crop_detection'
                : 'disease_detection',
            'disease': result['disease_name'],
            'confidence':
                ((result['confidence'] as num?) ?? 0).toDouble() / 100,
            'crop_type': cropType.isEmpty ? null : cropType,
            'severity': result['severity'],
            'treatment': result['treatment_plan'],
            'area_acres': areaAcres,
          },
        );
      }

      if (widget.mode == CropScanMode.cropDetection) {
        result = _asCropDetection(result);
      }

      if (widget.mode == CropScanMode.diseaseDetection &&
          cropType.isNotEmpty &&
          _hasFertilizerContext) {
        final fertilizer = await _predictFertilizer(online, cropType);
        if (fertilizer != null) {
          result = {
            ...result,
            'recommended_fertilizer': fertilizer['fertilizer'],
            'fertilizer_confidence':
                ((fertilizer['confidence'] as num?) ?? 0).toDouble() * 100,
            'fertilizer_tip': fertilizer['application_tip'] ?? '',
            'fertilizer_top': fertilizer['top_recommendations'] ?? const [],
          };
        }
      }

      if (widget.mode == CropScanMode.diseaseDetection && online) {
        final advisory = await _fetchCropAdvice(result, cropType, areaAcres);
        if (advisory != null && advisory.isNotEmpty) {
          result = {
            ...result,
            'advisory': advisory,
          };
        }
      }

      result = {
        ...result,
        'image_url': _img?.path ?? '',
        'crop_type': cropType,
        'area_acres': areaAcres,
      };

      await DB.saveScan(
        DateTime.now().millisecondsSinceEpoch.toString(),
        {
          'type': 'crop',
          'title': H.displayText(
            result['disease_name']?.toString() ??
                _tr('cropDisease', 'Crop Section'),
          ),
          'result': H.cap(
            H.displayText(
              widget.mode == CropScanMode.cropDetection
                  ? (result['result_tag'] ?? _tr('detectedLabel', 'Detected'))
                  : (result['severity'] ?? _tr('scannedLabel', 'Scanned')),
            ),
          ),
          'ts': DateTime.now().toIso8601String(),
          'source': result['source'] ?? (online ? 'cloud' : 'offline'),
        },
      );

      if (mounted) {
        if (_usedOfflineFallback) {
          H.snack(
            context,
            _tr(
              'cropCloudUnavailable',
              'Cloud crop scan is unavailable right now. Using offline AI result.',
            ),
          );
        }
        Navigator.pushNamed(context, Routes.cropResult, arguments: result);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        H.snack(context, msg.isEmpty ? _tr('analysisFailedRetry', 'Analysis failed. Try again.') : msg,
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _hasFertilizerContext {
    return _tempCtrl.text.trim().isNotEmpty &&
        _humidityCtrl.text.trim().isNotEmpty &&
        _moistureCtrl.text.trim().isNotEmpty &&
        _soilTypeCtrl.text.trim().isNotEmpty &&
        _nitrogenCtrl.text.trim().isNotEmpty &&
        _potassiumCtrl.text.trim().isNotEmpty &&
        _phosphorousCtrl.text.trim().isNotEmpty;
  }

  Future<Map<String, dynamic>?> _predictFertilizer(
      bool online, String cropType) async {
    final payload = {
      'temperature': double.tryParse(_tempCtrl.text.trim()),
      'humidity': double.tryParse(_humidityCtrl.text.trim()),
      'moisture': double.tryParse(_moistureCtrl.text.trim()),
      'soil_type': _soilTypeCtrl.text.trim(),
      'crop_type': cropType,
      'nitrogen': double.tryParse(_nitrogenCtrl.text.trim()),
      'potassium': double.tryParse(_potassiumCtrl.text.trim()),
      'phosphorous': double.tryParse(_phosphorousCtrl.text.trim()),
    };
    if (payload.values.any((value) => value == null || value == ''))
      return null;

    if (online) {
      final response = await ApiSvc().post(ApiK.fertilizerPredict, payload);
      if (response.ok && response.data != null) {
        final data =
            response.data!['data'] as Map<String, dynamic>? ?? response.data!;
        return data;
      }
    }

    return TFSvc().predictFertilizer(
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

  Future<String?> _fetchCropAdvice(
      Map<String, dynamic> result, String cropType, double areaAcres) async {
    final response = await ApiSvc().post(ApiK.llmAdvise, {
      'module': 'crop',
      'data': {
        'crop_type': cropType.isEmpty ? 'Unknown crop' : cropType,
        'disease_name': result['disease_name'] ?? 'Unknown',
        'severity': result['severity'] ?? 'medium',
        'treatment': result['treatment_plan'] ?? '',
        'prevention': result['description'] ?? '',
        'recommended_fertilizer':
            result['recommended_fertilizer'] ?? 'Not available',
        'fertilizer_tip': result['fertilizer_tip'] ??
            'Use only after checking crop condition and soil status.',
        'area_acres': areaAcres.toString(),
      },
      'language': LangSvc().lang,
    });

    if (!response.ok || response.data == null) return null;
    final payload =
        response.data!['data'] as Map<String, dynamic>? ?? response.data!;
    return payload['advice']?.toString();
  }

  Future<void> _toggleVoice() async {
    if (_backendRecording) {
      final res = await VoiceSvc().stopBackendRecordingAndTranscribe(
        lang: LangSvc().lang,
        detectIntent: false,
        prompt: _whisperPrompt,
      );
      if (!mounted) return;
      setState(() => _backendRecording = false);
      if (res.ok && res.data != null) {
        final payload = res.data!;
        final data = payload['data'] as Map<String, dynamic>? ?? payload;
        final text = (data['text'] ?? '').toString().trim();
        if (text.isNotEmpty) {
          setState(() => _setCropType(text));
        } else {
          H.snack(context, _tr('noSpeechDetected', 'No speech detected'), error: true);
        }
      } else {
        H.snack(context, res.error ?? _tr('voiceFailed', 'AI voice request failed'), error: true);
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
      onResult: (t) {
        setState(() {
          _setCropType(t);
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
        H.snack(context, _tr('recordingAiVoice', 'Recording for AI voice... tap Stop when finished.'));
      } else {
        H.snack(
          context,
          _tr('voiceUnavailable', 'Voice input is unavailable right now'),
          error: true,
        );
      }
    }
  }

  Future<void> _toggleWhisper() async {
    if (_backendRecording) {
      setState(() => _busy = true);
      final res = await VoiceSvc().stopBackendRecordingAndProcessVoice(
        module: 'crop',
        context: {
          'mode': widget.mode.name,
          'crop_type': _cropTypeCtrl.text.trim(),
          'area_acres': _areaCtrl.text.trim(),
        },
        lang: LangSvc().lang,
        detectIntent: true,
        prompt: _whisperPrompt,
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
          setState(() => _setCropType(text));
          await VoiceSvc().setLang(LangSvc().lang);
          await VoiceSvc().speakWithFallback(
            audioUrl: data['audio_url']?.toString(),
            fallbackText: (data['ai_response'] ?? '').toString(),
          );
          H.snack(context, _tr('voiceProcessed', 'AI voice response ready'));
        } else {
          H.snack(context, _tr('noSpeechDetected', 'No speech detected'), error: true);
        }
      } else {
        H.snack(context, res.error ?? _tr('voiceFailed', 'AI voice request failed'),
            error: true);
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
      H.snack(context, _tr('whisperNeedsInternet', 'AI voice needs internet and microphone permission'),
          error: true);
      return;
    }
    setState(() => _backendRecording = true);
  }

  Future<Map<String, dynamic>> _offline() async {
    final inf = await TFSvc().classifyCrop(_img!);
    final lbl = inf['label'] as String? ?? 'Unknown';
    if (lbl == 'Model not loaded') {
      final error = inf['error']?.toString();
      throw Exception(error == null || error.isEmpty ? lbl : '$lbl: $error');
    }

    final conf = (inf['confidence'] as double? ?? 0) * 100;
    final isHealthy = lbl.toLowerCase().contains('healthy');
    return {
      'analysis_mode': 'disease_detection',
      'disease_name': lbl,
      'confidence': conf,
      'severity': isHealthy ? 'healthy' : (conf > 80 ? 'high' : 'medium'),
      'description': isHealthy
          ? 'Your crop appears healthy. Maintain current care routine.'
          : 'Disease detected. Early treatment is recommended.',
      'symptoms': isHealthy
          ? []
          : ['Discoloration on leaves', 'Irregular spots', 'Reduced growth'],
      'treatment_plan': isHealthy
          ? 'Continue regular watering and fertilization schedule.'
          : 'Apply appropriate fungicide. Remove severely affected leaves. Improve drainage.',
      'treatment_cost': isHealthy ? 0.0 : 1200.0,
      'estimated_loss': isHealthy ? 0.0 : 18000.0,
      'image_url': _img!.path,
      'scanned_at': DateTime.now().toIso8601String(),
      'source': 'offline',
    };
  }

  Map<String, dynamic> _normalizeOnline(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final roi = data['roi'] as Map<String, dynamic>? ?? {};
    return {
      'analysis_mode': 'disease_detection',
      'disease_name': data['disease_display'] ?? data['disease'] ?? 'Unknown',
      'confidence': ((data['confidence'] as num?) ?? 0).toDouble() * 100,
      'severity': (data['severity'] ?? 'medium').toString().toLowerCase(),
      'description': data['prevention'] ?? 'Cloud diagnosis completed.',
      'symptoms': data['symptoms'] ?? <String>[],
      'treatment_plan': data['treatment'] ?? '',
      'treatment_cost': (roi['treatment_cost'] as num?)?.toDouble() ?? 0,
      'estimated_loss': (roi['estimated_loss'] as num?)?.toDouble() ?? 0,
      'image_url': _img!.path,
      'scanned_at': DateTime.now().toIso8601String(),
      'source': 'cloud',
    };
  }

  Map<String, dynamic> _asCropDetection(Map<String, dynamic> source) {
    final label = (source['disease_name'] ?? 'Unknown').toString();
    final cropName = _extractCropName(label);
    return {
      ...source,
      'analysis_mode': 'crop_detection',
      'disease_name': cropName,
      'severity': 'detected',
      'description':
          'The AI model identified this crop from the uploaded plant image.',
      'symptoms': <String>[],
      'treatment_plan':
          'Use this detected crop type to continue disease checks, advisory, and farm planning.',
      'treatment_cost': 0.0,
      'estimated_loss': 0.0,
      'result_tag': 'Detected',
    };
  }

  String _extractCropName(String label) {
    final base =
        label.split('___').first.replaceAll('_', ' ').replaceAll(',', '');
    final normalized = base.trim();
    if (normalized.isEmpty) return 'Unknown Crop';
    return normalized
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(title: Text(_screenTitle), backgroundColor: AppColors.surface),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _sheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    height: 255,
                    decoration: BoxDecoration(
                      color: _img == null ? AppColors.cropFaint : null,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _img == null
                            ? AppColors.cropGreen.withValues(alpha: 0.35)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: _img != null
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.09),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _img == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: AppColors.cropGreen
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.cropGreen,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _heroTitle,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.cropGreen,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _heroSubtitle,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_img!, fit: BoxFit.cover),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => setState(() => _img = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white, size: 15),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _tr('tapToChange', 'Tap to change'),
                                    style: GoogleFonts.dmSans(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Btn.outline(
                        label: _tr('camera', 'Camera'),
                        icon: Icons.camera_alt_outlined,
                        fg: AppColors.cropGreen,
                        onTap: () => _pick(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Btn.outline(
                        label: _tr('gallery', 'Gallery'),
                        icon: Icons.photo_library_outlined,
                        fg: AppColors.cropGreen,
                        onTap: () => _pick(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _detailsLabel,
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
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _listening
                              ? AppColors.danger
                              : AppColors.cropFaint,
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
                                  : AppColors.cropGreen,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _listening ? _tr('stop', 'Stop') : _tr('voice', 'Voice'),
                              style: GoogleFonts.dmSans(
                                color: _listening
                                    ? Colors.white
                                    : AppColors.cropGreen,
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
                            horizontal: 12, vertical: 6),
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
                              _backendRecording ? _tr('stop', 'Stop') : _tr('aiVoice', 'AI Voice'),
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
                if (widget.mode == CropScanMode.cropDetection)
                  TextField(
                    controller: _cropTypeCtrl,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _tr('cropNotes', 'Crop notes'),
                      hintText: _tr('cropNotesHint',
                          'e.g. broad leaves, field crop, green plant'),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedDiseasePlant,
                    isExpanded: true,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: _tr('plantName', 'Plant name'),
                      hintText: _tr('selectPlantName', 'Select the plant name'),
                    ),
                    selectedItemBuilder: (context) => _diseasePlantOptions
                        .map(
                          (plant) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _displayPlantName(plant),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    items: _diseasePlantOptions
                        .map(
                          (plant) => DropdownMenuItem<String>(
                            value: plant,
                            child: Text(
                              _displayPlantName(plant),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedDiseasePlant = value;
                        _cropTypeCtrl.text = value;
                      });
                    },
                  ),
                const SizedBox(height: 10),
                if (widget.mode == CropScanMode.diseaseDetection)
                  TextField(
                    controller: _areaCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: _tr('areaInAcres', 'Area in acres'),
                      hintText: '1.0',
                    ),
                  ),
                if (widget.mode == CropScanMode.diseaseDetection) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('optionalFertilizerInputs', 'Optional fertilizer recommendation inputs'),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tr('optionalFertilizerHelp', 'Fill these to add model-based fertilizer advice to the crop result, even offline.'),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _soilTypeCtrl,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: _tr('soilType', 'Soil type'),
                            hintText: _tr('soilTypeHint', 'Sandy, Loamy, Black, Red, Clayey'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _tempCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration:
                              InputDecoration(labelText: _tr('temperature', 'Temperature')),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _humidityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration:
                              InputDecoration(labelText: _tr('humidity', 'Humidity')),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _moistureCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration:
                              InputDecoration(labelText: _tr('moisture', 'Moisture')),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nitrogenCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration:
                              InputDecoration(labelText: _tr('nitrogen', 'Nitrogen')),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _potassiumCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration:
                              InputDecoration(labelText: _tr('potassium', 'Potassium')),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phosphorousCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration:
                              InputDecoration(labelText: _tr('phosphorous', 'Phosphorous')),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_listening || _backendRecording) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _backendRecording
                          ? AppColors.warningFaint
                          : AppColors.dangerFaint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _backendRecording
                              ? Icons.cloud_rounded
                              : Icons.mic_rounded,
                          color: _backendRecording
                              ? AppColors.warning
                              : AppColors.danger,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _backendRecording
                                ? _tr('recordingAiVoice', 'Recording for AI voice... tap Stop when finished.')
                                : _voiceHint,
                            style: GoogleFonts.dmSans(
                              color: _backendRecording
                                  ? AppColors.warning
                                  : AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Btn(
                  label: _analyzeLabel,
                  icon: Icons.psychology_rounded,
                  bg: AppColors.cropGreen,
                  onTap: _img != null ? _analyze : null,
                  loading: _busy,
                ),
                const SizedBox(height: 24),
                _tips(),
              ],
            ),
          ),
          if (_busy)
            LoadingOverlay(
              msg: widget.mode == CropScanMode.cropDetection
                  ? _tr('detectingCrop', 'Detecting crop with AI...')
                  : _tr('analyzingLeaf', 'Analyzing leaf with AI...'),
            ),
        ],
      ),
    );
  }

  void _sheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cropFaint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.cropGreen, size: 19),
                ),
                title: Text(_tr('takePhoto', 'Take Photo'),
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cropFaint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.cropGreen, size: 19),
                ),
                title: Text(_tr('chooseFromGallery', 'Choose from Gallery'),
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tips() {
    final tips = [
      _tr('tipSingleLeaf', 'Photograph a single leaf, not the whole plant'),
      _tr('tipLighting', 'Ensure good natural lighting - avoid shadows'),
      widget.mode == CropScanMode.cropDetection
          ? _tr('tipPlantVisible', 'Keep the plant and leaves clearly visible in the frame')
          : _tr('tipFocusArea', 'Focus on the discolored or infected area'),
      _tr('tipOfflineModel', 'Works fully offline with on-device AI model'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cropFaint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cropGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  color: AppColors.cropGreen, size: 15),
              const SizedBox(width: 7),
              Text(
                _tr('tipsBestResults', 'Tips for best results'),
                style: GoogleFonts.dmSans(
                  color: AppColors.cropGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.cropGreen, size: 13),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary, fontSize: 12),
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
}
