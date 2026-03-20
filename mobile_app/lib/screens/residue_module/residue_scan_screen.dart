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
import '../../services/language_service.dart';
import '../../services/local_db_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class ResidueScanScreen extends StatefulWidget {
  const ResidueScanScreen({super.key});

  @override
  State<ResidueScanScreen> createState() => _ResidueScanScreenState();
}

class _ResidueScanScreenState extends State<ResidueScanScreen> {
  File? _img;
  bool _busy = false;
  bool _listening = false;
  bool _backendRecording = false;
  String _type = 'Wheat Straw';
  String _moisture = 'Medium';
  final _picker = ImagePicker();
  final _noteCtrl = TextEditingController();

  static const _types = [
    'Wheat Straw',
    'Rice Husk',
    'Sugarcane Bagasse',
    'Cotton Stalks',
    'Corn Stalks',
    'Other'
  ];
  static const _moistures = ['Low (dry)', 'Medium', 'High (wet)'];

  String t(String key) => LangSvc().t(key);

  String _typeLabel(String type) {
    switch (type) {
      case 'Wheat Straw':
        return t('wheatStraw');
      case 'Rice Husk':
        return t('riceHusk');
      case 'Sugarcane Bagasse':
        return t('sugarcaneBagasse');
      case 'Cotton Stalks':
        return t('cottonStalks');
      case 'Corn Stalks':
        return t('cornStalks');
      default:
        return t('otherLabel');
    }
  }

  String _moistureLabel(String value) {
    switch (value) {
      case 'Low (dry)':
        return t('lowDry');
      case 'Medium':
        return t('mediumLabel');
      case 'High (wet)':
        return t('highWet');
      default:
        return value;
    }
  }

  @override
  void dispose() {
    unawaited(VoiceSvc().stop());
    unawaited(VoiceSvc().cancelBackendRecording());
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final file =
        await _picker.pickImage(source: src, imageQuality: 80, maxWidth: 1024);
    if (file != null) setState(() => _img = File(file.path));
  }

  Future<void> _analyze() async {
    if (_img == null) {
      H.snack(context, t('pleaseTakePhotoFirst'), error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final online = await ConnSvc().check();
      Map<String, dynamic> result;
      if (online) {
        final response = await ApiSvc().multipart(
          ApiK.residue,
          _img!,
          {'residue_type': _type, 'moisture': _moisture},
        );
        result = (response.ok && response.data != null)
            ? response.data!
            : _offline();
      } else {
        result = _offline();
        await DB.addSyncRecord(
          module: 'residue',
          payload: {
            'residue_type': _type,
            'moisture': _moisture,
            'best_option': result['best_option'],
            'projected_earnings': result['projected_earnings'],
          },
        );
      }

      await DB.saveScan(
        DateTime.now().millisecondsSinceEpoch.toString(),
        {
          'type': 'residue',
          'title': '$_type - ${result['best_option'] ?? 'Analyzed'}',
          'result':
              H.compact((result['projected_earnings'] as num? ?? 0).toDouble()),
          'ts': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        Navigator.pushNamed(context, Routes.residueIncome, arguments: result);
      }
    } catch (_) {
      if (mounted) H.snack(context, t('analysisFailedRetry'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyResidueTranscript(String text) {
    final lower = text.toLowerCase();
    String nextType = _type;
    String nextMoisture = _moisture;

    if (lower.contains('wheat')) nextType = 'Wheat Straw';
    if (lower.contains('rice')) nextType = 'Rice Husk';
    if (lower.contains('sugarcane')) nextType = 'Sugarcane Bagasse';
    if (lower.contains('cotton')) nextType = 'Cotton Stalks';
    if (lower.contains('corn') || lower.contains('maize'))
      nextType = 'Corn Stalks';
    if (lower.contains('dry') || lower.contains('low moisture'))
      nextMoisture = 'Low (dry)';
    if (lower.contains('wet') || lower.contains('high moisture'))
      nextMoisture = 'High (wet)';
    if (lower.contains('medium')) nextMoisture = 'Medium';

    setState(() {
      _type = nextType;
      _moisture = nextMoisture;
      _noteCtrl.text = text;
    });
  }

  Future<void> _toggleVoice() async {
    if (_backendRecording) {
      await VoiceSvc().cancelBackendRecording();
      if (mounted) setState(() => _backendRecording = false);
    }
    if (_listening) {
      await VoiceSvc().stop();
      setState(() => _listening = false);
    } else {
      setState(() => _listening = true);
      final started = await VoiceSvc().listen(
        onResult: (text) {
          _applyResidueTranscript(text);
          setState(() => _listening = false);
        },
        lang: LangSvc().lang,
      );
      if (!started && mounted) {
        setState(() => _listening = false);
        H.snack(context, 'Voice input is unavailable right now', error: true);
      }
    }
  }

  Future<void> _toggleWhisper() async {
    if (_backendRecording) {
      setState(() => _busy = true);
      final response = await VoiceSvc().stopBackendRecordingAndProcessVoice(
        module: 'residue',
        context: {
          'residue_type': _type,
          'moisture': _moisture,
          'notes': _noteCtrl.text.trim(),
        },
        lang: LangSvc().lang,
        detectIntent: true,
        prompt:
            'Transcribe residue crop type and moisture condition clearly for income analysis.',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _backendRecording = false;
      });

      if (response.ok && response.data != null) {
        final payload = response.data!;
        final data = payload['data'] as Map<String, dynamic>? ?? payload;
        final text = (data['user_text'] ?? '').toString().trim();
        if (text.isNotEmpty) {
          _applyResidueTranscript(text);
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
        H.snack(context, response.error ?? t('voiceFailed'),
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
      H.snack(context, t('whisperNeedsInternet'),
          error: true);
      return;
    }
    setState(() => _backendRecording = true);
  }

  Map<String, dynamic> _offline() {
    final baseQty = switch (_type) {
      'Wheat Straw' => 520.0,
      'Rice Husk' => 460.0,
      'Sugarcane Bagasse' => 610.0,
      'Cotton Stalks' => 430.0,
      'Corn Stalks' => 500.0,
      _ => 400.0,
    };
    final moistureFactor = switch (_moisture) {
      'Low (dry)' => 1.0,
      'Medium' => 0.9,
      'High (wet)' => 0.75,
      _ => 0.9,
    };
    final quantity = baseQty * moistureFactor;
    final options = <String, double>{
      'Compost': quantity * 5.5,
      'Cattle Fodder': (_type == 'Rice Husk' ? quantity * 4.0 : quantity * 7.0),
      'Bio-Briquettes': quantity * (_moisture == 'High (wet)' ? 10.0 : 14.0),
    };
    final sorted = options.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'residue_type': _type,
      'moisture_level': _moisture,
      'estimated_quantity_kg': quantity.roundToDouble(),
      'best_option': sorted.first.key,
      'projected_earnings': sorted.first.value.roundToDouble(),
      'all_options':
          options.map((key, value) => MapEntry(key, value.roundToDouble())),
      'image_url': _img?.path ?? '',
      'analyzed_at': DateTime.now().toIso8601String(),
      'description':
          'Offline estimate generated from residue type and moisture. Connect online for image-assisted analysis and nearby buyer suggestions.',
      'source': 'offline',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(t('residueAnalysisTitle')),
          backgroundColor: AppColors.surface),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('residueType'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _type,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textPrimary),
                  items: _types
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(_typeLabel(type))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),
                Text(
                  t('moistureLevel'),
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _moistures.asMap().entries.map((entry) {
                    final selected = entry.value == _moisture;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _moisture = entry.value),
                        child: Container(
                          margin: EdgeInsets.only(
                              right: entry.key < _moistures.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.purpleDark
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selected
                                    ? AppColors.purpleDark
                                    : AppColors.border),
                          ),
                          child: Text(
                            _moistureLabel(entry.value),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('voiceDetailsOptional'),
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
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
                              : AppColors.purpleFaint,
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
                                    : AppColors.purpleDark,
                                size: 15),
                            const SizedBox(width: 5),
                            Text(
                              _listening ? t('stop') : t('voice'),
                              style: GoogleFonts.dmSans(
                                color: _listening
                                    ? Colors.white
                                    : AppColors.purpleDark,
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
                                  : AppColors.border),
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
                                size: 15),
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
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: t('voiceNotes'),
                    hintText: t('voiceNotesHintResidue'),
                  ),
                ),
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
                                ? t('recordingAiVoice')
                                : t('residueListening'),
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
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _pick(ImageSource.camera),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 210,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _img == null ? AppColors.purpleFaint : null,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _img == null
                            ? AppColors.purpleDark.withValues(alpha: 0.35)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _img == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.purpleDark
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.recycling_rounded,
                                    color: AppColors.purpleDark, size: 30),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                t('residuePhotoTitle'),
                                style: GoogleFonts.dmSans(
                                  color: AppColors.purpleDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t('residuePhotoSub'),
                                style: GoogleFonts.dmSans(
                                    color: AppColors.textTertiary,
                                    fontSize: 12),
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
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Btn(
                  label: t('calculateIncome'),
                  icon: Icons.currency_rupee_rounded,
                  bg: AppColors.purpleDark,
                  onTap: _img != null ? _analyze : null,
                  loading: _busy,
                ),
                const SizedBox(height: 16),
                _tip(),
              ],
            ),
          ),
          if (_busy) const LoadingOverlay(msg: 'Calculating income options...'),
        ],
      ),
    );
  }

  Widget _tip() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.purpleFaint,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.purpleDark.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded,
                color: AppColors.purpleDark, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t('residueTip'),
                style: GoogleFonts.dmSans(
                  color: AppColors.purpleDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
}
