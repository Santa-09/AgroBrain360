import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFSvc {
  static final TFSvc _i = TFSvc._();
  factory TFSvc() => _i;
  TFSvc._();

  Interpreter? _cropDisease;
  Future<void>? _cropDiseaseLoadFuture;
  String? _cropDiseaseLoadError;

  Interpreter? _cropRecommendation;
  Future<void>? _cropRecommendationLoadFuture;
  Map<String, dynamic>? _cropRecommendationMeta;

  Interpreter? _fertilizer;
  Future<void>? _fertilizerLoadFuture;
  Map<String, dynamic>? _fertilizerMeta;

  Interpreter? _livestock;
  Future<void>? _livestockLoadFuture;

  static const diseaseLabels = [
    'Apple___Apple_scab',
    'Apple___Black_rot',
    'Apple___Cedar_apple_rust',
    'Apple___healthy',
    'Blueberry___healthy',
    'Cherry_(including_sour)___Powdery_mildew',
    'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
    'Corn_(maize)___Common_rust_',
    'Corn_(maize)___Northern_Leaf_Blight',
    'Corn_(maize)___healthy',
    'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)',
    'Peach___Bacterial_spot',
    'Peach___healthy',
    'Pepper,_bell___Bacterial_spot',
    'Pepper,_bell___healthy',
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
    'Raspberry___healthy',
    'Rice___Bacterial_leaf_blight',
    'Rice___Brown_spot',
    'Rice___Leaf_smut',
    'Soybean___healthy',
    'Squash___Powdery_mildew',
    'Strawberry___Leaf_scorch',
    'Strawberry___healthy',
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy',
  ];

  static final List<String> diseasePlantNames = () {
    final seen = <String>{};
    final plants = <String>[];
    for (final label in diseaseLabels) {
      final raw = label.split('___').first.replaceAll('_', ' ').replaceAll(',', '');
      final normalized = raw
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
          .join(' ');
      if (normalized.isNotEmpty && seen.add(normalized)) {
        plants.add(normalized);
      }
    }
    plants.sort();
    return plants;
  }();

  static const livestockLabels = [
    'foot-and-mouth',
    'healthy',
    'lumpy',
  ];

  Future<void> load() async {
    await Future.wait([
      _safeLoad(_loadCropDiseaseModel),
      _safeLoad(_loadCropRecommendationModel),
      _safeLoad(_loadFertilizerModel),
      _safeLoad(_loadLivestockModel),
    ]);
  }

  Future<void> _safeLoad(Future<void> Function() loader) async {
    try {
      await loader();
    } catch (_) {
      // Keep app startup resilient in local/dev mode even if one model asset
      // is unavailable; feature screens already handle model-not-loaded cases.
    }
  }

  Future<void> _loadCropDiseaseModel() {
    return _cropDiseaseLoadFuture ??= () async {
      if (_cropDisease != null) return;
      try {
        _cropDisease =
            await Interpreter.fromAsset('assets/models/crop_disease.tflite');
        _cropDiseaseLoadError = null;
      } catch (e) {
        _cropDiseaseLoadError = e.toString();
        _cropDiseaseLoadFuture = null;
        rethrow;
      }
    }();
  }

  Future<void> _loadCropRecommendationModel() {
    return _cropRecommendationLoadFuture ??= () async {
      if (_cropRecommendation != null && _cropRecommendationMeta != null) {
        return;
      }
      try {
        _cropRecommendation = await Interpreter.fromAsset(
          'assets/models/crop_recommendation.tflite',
        );
        final metaText = await rootBundle
            .loadString('assets/models/crop_recommendation_meta.json');
        _cropRecommendationMeta = jsonDecode(metaText) as Map<String, dynamic>;
      } catch (_) {
        _cropRecommendationLoadFuture = null;
        rethrow;
      }
    }();
  }

  Future<void> _loadFertilizerModel() {
    return _fertilizerLoadFuture ??= () async {
      if (_fertilizer != null && _fertilizerMeta != null) return;
      try {
        _fertilizer = await Interpreter.fromAsset(
          'assets/models/fertilizer_recommendation.tflite',
        );
        final metaText = await rootBundle
            .loadString('assets/models/fertilizer_recommendation_meta.json');
        _fertilizerMeta = jsonDecode(metaText) as Map<String, dynamic>;
      } catch (_) {
        _fertilizerLoadFuture = null;
        rethrow;
      }
    }();
  }

  Future<void> _loadLivestockModel() {
    return _livestockLoadFuture ??= () async {
      if (_livestock != null) return;
      try {
        _livestock =
            await Interpreter.fromAsset('assets/models/livestock_model.tflite');
      } catch (_) {
        _livestockLoadFuture = null;
        rethrow;
      }
    }();
  }

  Future<Map<String, dynamic>> classifyCrop(File image) async {
    if (_cropDisease == null) {
      try {
        await _loadCropDiseaseModel();
      } catch (e) {
        return {
          'label': 'Model not loaded',
          'confidence': 0.0,
          'error': _cropDiseaseLoadError ?? e.toString(),
        };
      }
    }
    if (_cropDisease == null) {
      return {
        'label': 'Model not loaded',
        'confidence': 0.0,
        'error': _cropDiseaseLoadError ?? 'Interpreter initialization failed',
      };
    }

    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return {'label': 'Invalid image', 'confidence': 0.0};

    final resized = img.copyResize(decoded, width: 224, height: 224);
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    final outputShape = _cropDisease!.getOutputTensor(0).shape;
    final classCount =
        outputShape.isNotEmpty ? outputShape.last : diseaseLabels.length;
    final output = [List<double>.filled(classCount, 0.0)];
    _cropDisease!.run(input, output);
    final scores = output[0];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxIdx = scores.indexOf(maxScore);
    final label =
        maxIdx < diseaseLabels.length ? diseaseLabels[maxIdx] : 'Class_$maxIdx';
    return {'label': label, 'confidence': maxScore, 'index': maxIdx};
  }

  Future<Map<String, dynamic>> classifyLivestock(File image) async {
    try {
      await _loadLivestockModel();
    } catch (e) {
      return {
        'label': 'Model not loaded',
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
    if (_livestock == null) {
      return {
        'label': 'Model not loaded',
        'confidence': 0.0,
        'error': 'Interpreter initialization failed',
      };
    }
    return _classifyImage(image, _livestock!, livestockLabels);
  }

  Future<Map<String, dynamic>> predictCropRecommendation({
    required double nitrogen,
    required double phosphorous,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
  }) async {
    await _loadCropRecommendationModel();
    if (_cropRecommendation == null || _cropRecommendationMeta == null) {
      return {
        'crop': 'Model not loaded',
        'confidence': 0.0,
        'error': 'Crop recommendation model is unavailable on this build.',
      };
    }
    final meta = _cropRecommendationMeta!;
    final classes = (meta['classes'] as List).cast<String>();

    final featureVector = <double>[
      nitrogen,
      phosphorous,
      potassium,
      temperature,
      humidity,
      ph,
      rainfall,
      nitrogen + phosphorous + potassium,
      nitrogen / (phosphorous + 1e-6),
      nitrogen / (potassium + 1e-6),
      temperature * humidity / 100.0,
      (ph - 6.5) * (ph - 6.5),
      rainfall / (temperature + 1e-6),
    ];

    final output = [List<double>.filled(classes.length, 0.0)];
    _cropRecommendation!.run([featureVector], output);
    final scores = output[0];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxIdx = scores.indexOf(maxScore);

    return {
      'crop': classes[maxIdx],
      'confidence': maxScore,
    };
  }

  Future<Map<String, dynamic>> predictFertilizer({
    required double temperature,
    required double humidity,
    required double moisture,
    required String soilType,
    required String cropType,
    required double nitrogen,
    required double potassium,
    required double phosphorous,
  }) async {
    await _loadFertilizerModel();
    if (_fertilizer == null || _fertilizerMeta == null) {
      return {
        'fertilizer': 'Model not loaded',
        'confidence': 0.0,
        'top_recommendations': const [],
        'application_tip': 'Fertilizer model is unavailable on this build.',
        'summary': 'Offline fertilizer prediction could not be initialized.',
        'error': 'Fertilizer model not loaded',
      };
    }
    final meta = _fertilizerMeta!;
    final classes = (meta['classes'] as List).cast<String>();
    final soilTypes = (meta['soil_types'] as List).cast<String>();
    final cropTypes = (meta['crop_types'] as List).cast<String>();
    final means = (meta['numeric_means'] as List)
        .map((value) => (value as num).toDouble())
        .toList();
    final stds = (meta['numeric_stds'] as List)
        .map((value) => (value as num).toDouble())
        .toList();

    final numeric = <double>[
      temperature,
      humidity,
      moisture,
      nitrogen,
      potassium,
      phosphorous,
    ];

    final normalized = <double>[];
    for (var i = 0; i < numeric.length; i++) {
      final std = stds[i] == 0 ? 1.0 : stds[i];
      normalized.add((numeric[i] - means[i]) / std);
    }

    final soilOneHot = List<double>.filled(soilTypes.length, 0.0);
    final cropOneHot = List<double>.filled(cropTypes.length, 0.0);
    final soilIndex = soilTypes
        .indexWhere((value) => value.toLowerCase() == soilType.toLowerCase());
    final cropIndex = cropTypes
        .indexWhere((value) => value.toLowerCase() == cropType.toLowerCase());
    if (soilIndex >= 0) soilOneHot[soilIndex] = 1.0;
    if (cropIndex >= 0) cropOneHot[cropIndex] = 1.0;

    final inputVector = <double>[...normalized, ...soilOneHot, ...cropOneHot];
    final output = [List<double>.filled(classes.length, 0.0)];
    _fertilizer!.run([inputVector], output);
    final scores = output[0];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxIdx = scores.indexOf(maxScore);

    final ranked = List.generate(
      classes.length,
      (index) => {
        'fertilizer': classes[index],
        'confidence': scores[index],
      },
    )..sort((a, b) =>
        ((b['confidence'] as double).compareTo(a['confidence'] as double)));

    return {
      'fertilizer': classes[maxIdx],
      'confidence': maxScore,
      'top_recommendations': ranked.take(3).toList(),
      'application_tip':
          'Offline recommendation generated from the on-device fertilizer model.',
      'summary':
          'This offline result is based on the trained fertilizer recommendation model.',
    };
  }

  void dispose() {
    _cropDisease?.close();
    _cropRecommendation?.close();
    _fertilizer?.close();
    _livestock?.close();
    _cropDisease = null;
    _cropRecommendation = null;
    _fertilizer = null;
    _livestock = null;
    _cropDiseaseLoadFuture = null;
    _cropRecommendationLoadFuture = null;
    _fertilizerLoadFuture = null;
    _livestockLoadFuture = null;
    _cropDiseaseLoadError = null;
    _cropRecommendationMeta = null;
    _fertilizerMeta = null;
  }

  Future<Map<String, dynamic>> _classifyImage(
    File image,
    Interpreter interpreter,
    List<String> labels,
  ) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return {'label': 'Invalid image', 'confidence': 0.0};

    final resized = img.copyResize(decoded, width: 224, height: 224);
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    final outputShape = interpreter.getOutputTensor(0).shape;
    final classCount =
        outputShape.isNotEmpty ? outputShape.last : labels.length;
    final output = [List<double>.filled(classCount, 0.0)];
    interpreter.run(input, output);
    final scores = output[0];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxIdx = scores.indexOf(maxScore);
    final label = maxIdx < labels.length ? labels[maxIdx] : 'Class_$maxIdx';
    return {'label': label, 'confidence': maxScore, 'index': maxIdx};
  }
}
