import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/constants/api_constants.dart';
import '../models/response_model.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

class VoiceSvc {
  static final VoiceSvc _i = VoiceSvc._();
  factory VoiceSvc() => _i;
  VoiceSvc._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _ready = false;
  bool _listening = false;
  bool _backendRecording = false;
  List<LocaleName> _availableLocales = const [];
  String? _recordingPath;
  bool _enabled = true;
  bool get listening => _listening;
  bool get backendRecording => _backendRecording;
  bool get enabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('voice_enabled') ?? true;
    _ready = await _initializeSpeech();
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', value);
    if (!value) {
      await stop();
      await cancelBackendRecording();
    }
  }

  Future<bool> _initializeSpeech() async {
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) return false;
      final ready = await _stt.initialize(
        onError: (_) => _listening = false,
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _listening = false;
          }
        },
      );
      if (ready) {
        try {
          _availableLocales = await _stt.locales();
        } catch (_) {
          _availableLocales = const [];
        }
      }
      return ready;
    } catch (_) {
      return false;
    }
  }

  Future<void> setLang(String code) async {
    try {
      await _tts.setLanguage(_bestTtsLocale(code));
    } catch (_) {
      await _tts.setLanguage('en-IN');
    }
  }

  Future<bool> listen({
    required void Function(String) onResult,
    String lang = 'en',
  }) async {
    if (!_enabled || _listening || _backendRecording) return false;
    if (!_ready) {
      _ready = await _initializeSpeech();
    }
    if (!_ready) return false;
    try {
      Future<bool> startListen({String? localeId}) async {
        final started = await _stt.listen(
          onResult: (r) {
            if (r.finalResult) {
              onResult(r.recognizedWords);
              _listening = false;
            }
          },
          localeId: localeId,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        );
        return started == true;
      }

      bool started;
      try {
        started = await startListen(localeId: _bestSttLocale(lang));
      } catch (_) {
        started = await startListen();
      }
      _listening = started;
      return started;
    } catch (_) {
      _listening = false;
      return false;
    }
  }

  String _bestSttLocale(String code) {
    final preferred = <String>[
      switch (code) {
        'hi' => 'hi_IN',
        'od' => 'or_IN',
        'ta' => 'ta_IN',
        'te' => 'te_IN',
        _ => 'en_IN',
      },
      switch (code) {
        'hi' => 'hi-IN',
        'od' => 'or-IN',
        'ta' => 'ta-IN',
        'te' => 'te-IN',
        _ => 'en-IN',
      },
    ];

    final ids = _availableLocales.map((locale) => locale.localeId).toList();
    for (final candidate in preferred) {
      if (ids.contains(candidate)) return candidate;
    }

    final prefixes = <String>[
      switch (code) {
        'hi' => 'hi',
        'od' => 'or',
        'ta' => 'ta',
        'te' => 'te',
        _ => 'en',
      },
      'en',
    ];

    for (final prefix in prefixes) {
      for (final locale in _availableLocales) {
        final normalized = locale.localeId.toLowerCase().replaceAll('-', '_');
        if (normalized.startsWith('${prefix.toLowerCase()}_')) {
          return locale.localeId;
        }
      }
    }

    return 'en_IN';
  }

  String _bestTtsLocale(String code) {
    return switch (code) {
      'hi' => 'hi-IN',
      'od' => 'or-IN',
      'ta' => 'ta-IN',
      'te' => 'te-IN',
      _ => 'en-IN',
    };
  }

  Future<void> stop() async {
    await _stt.stop();
    _listening = false;
  }

  Future<void> speak(String text) async {
    await _audioPlayer.stop();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakWithFallback({
    String? audioUrl,
    required String fallbackText,
  }) async {
    await _tts.stop();
    if (audioUrl != null && audioUrl.trim().isNotEmpty) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(ApiK.resolveUrl(audioUrl.trim())));
        return;
      } catch (_) {}
    }
    await speak(fallbackText);
  }

  Future<bool> startBackendRecording() async {
    if (!_enabled) return false;
    if (_backendRecording) return true;
    if (_listening) {
      await stop();
    }
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    if (!await ConnSvc().check()) return false;
    if (!await _recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/agrobrain_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordingPath = path;
      _backendRecording = true;
      return true;
    } catch (_) {
      _recordingPath = null;
      _backendRecording = false;
      return false;
    }
  }

  Future<void> cancelBackendRecording() async {
    if (!_backendRecording && _recordingPath == null) return;
    final audioPath = _recordingPath;
    _backendRecording = false;
    _recordingPath = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.cancel();
      }
    } catch (_) {}

    if (audioPath == null) return;
    try {
      final file = File(audioPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<Res<Map<String, dynamic>>> stopBackendRecordingAndTranscribe({
    String lang = 'en',
    bool detectIntent = true,
    String? prompt,
  }) async {
    if (!_backendRecording)
      return Res.fail('Whisper recording was not started');

    try {
      if (!await _recorder.isRecording()) {
        _backendRecording = false;
        _recordingPath = null;
        return Res.fail('Whisper recording is no longer active');
      }

      final stoppedPath = await _recorder.stop();
      _backendRecording = false;
      final audioPath = stoppedPath ?? _recordingPath;
      _recordingPath = null;

      if (audioPath == null) return Res.fail('No audio recording found');

      final file = File(audioPath);
      if (!await file.exists()) return Res.fail('Recorded audio file is missing');

      final result = await _multipartWithVoiceFallback(
        ApiK.voiceTranscribe,
        '${ApiK.local}/voice/transcribe',
        file,
        {
        'language': lang,
        'detect_intent': detectIntent.toString(),
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
        },
      );

      try {
        await file.delete();
      } catch (_) {}

      return result;
    } on SocketException {
      _backendRecording = false;
      _recordingPath = null;
      return Res.fail('No internet connection');
    } catch (e) {
      _backendRecording = false;
      _recordingPath = null;
      return Res.fail(e.toString());
    }
  }

  Future<Res<Map<String, dynamic>>> stopBackendRecordingAndProcessVoice({
    required String module,
    required Map<String, dynamic> context,
    String lang = 'en',
    bool detectIntent = true,
    String? prompt,
  }) async {
    if (!_backendRecording) {
      return Res.fail('Voice recording was not started');
    }

    try {
      if (!await _recorder.isRecording()) {
        _backendRecording = false;
        _recordingPath = null;
        return Res.fail('Voice recording is no longer active');
      }

      final stoppedPath = await _recorder.stop();
      _backendRecording = false;
      final audioPath = stoppedPath ?? _recordingPath;
      _recordingPath = null;

      if (audioPath == null) return Res.fail('No audio recording found');

      final file = File(audioPath);
      if (!await file.exists()) return Res.fail('Recorded audio file is missing');

      final result = await _multipartWithVoiceFallback(
        ApiK.voice,
        '${ApiK.local}/voice',
        file,
        {
        'module': module,
        'language': lang,
        'detect_intent': detectIntent.toString(),
        'context': jsonEncode(context),
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
        },
      );

      try {
        await file.delete();
      } catch (_) {}

      return result;
    } on SocketException {
      _backendRecording = false;
      _recordingPath = null;
      return Res.fail('No internet connection');
    } catch (e) {
      _backendRecording = false;
      _recordingPath = null;
      return Res.fail(e.toString());
    }
  }

  Future<Res<Map<String, dynamic>>> _multipartWithVoiceFallback(
    String primaryUrl,
    String localUrl,
    File file,
    Map<String, String> fields,
  ) async {
    final primary = await ApiSvc().multipart(
      primaryUrl,
      file,
      fields,
      ApiK.voiceTimeoutMs,
    );
    if (primary.ok) return primary;

    final shouldTryLocal = !ApiK.useLocal &&
        primaryUrl != localUrl &&
        ((primary.error?.contains('404') ?? false) ||
            (primary.error?.contains('Error 404') ?? false));
    if (!shouldTryLocal) return primary;

    return ApiSvc().multipart(
      localUrl,
      file,
      fields,
      ApiK.voiceTimeoutMs,
    );
  }
}
