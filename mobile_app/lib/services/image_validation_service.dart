import 'dart:io';

import 'package:image/image.dart' as img;

import 'tflite_service.dart';

class ImageValidationSvc {
  static final ImageValidationSvc _i = ImageValidationSvc._();
  factory ImageValidationSvc() => _i;
  ImageValidationSvc._();

  static const rejectionMessage =
      'Please recapture the image. This does not match a detectable disease input.';

  Future<ImageValidationResult> validateCropDiseaseImage(File image) async {
    final quality = await _checkQuality(image);
    if (!quality.valid) return quality;

    final inference = await TFSvc().classifyCrop(image);
    final label = (inference['label'] ?? '').toString();
    final confidence = ((inference['confidence'] as num?) ?? 0).toDouble();

    if (label == 'Invalid image') {
      return const ImageValidationResult.invalid(rejectionMessage);
    }
    if (label == 'Model not loaded') {
      final cropPattern = await _checkCropPattern(image);
      if (!cropPattern.valid) return cropPattern;
      return const ImageValidationResult.valid(details: {
        'fallback': 'quality_and_pattern_only',
      });
    }

    final cropPattern = await _checkCropPattern(image);
    final patternOk = cropPattern.valid;
    final strongModelMatch = confidence >= 0.78;
    final acceptableModelMatch = confidence >= 0.60 && patternOk;

    if (!strongModelMatch && !acceptableModelMatch) {
      return ImageValidationResult.invalid(
        rejectionMessage,
        details: {
          'label': label,
          'confidence': confidence,
          'patternValid': patternOk,
          ...cropPattern.details,
        },
      );
    }

    return ImageValidationResult.valid(details: {
      'label': label,
      'confidence': confidence,
      ...cropPattern.details,
    });
  }

  Future<ImageValidationResult> validateLivestockDiseaseImage(File image) async {
    final quality = await _checkQuality(image);
    if (!quality.valid) return quality;

    final inference = await TFSvc().classifyLivestock(image);
    final label = (inference['label'] ?? '').toString();
    final confidence = ((inference['confidence'] as num?) ?? 0).toDouble();

    if (label == 'Invalid image') {
      return const ImageValidationResult.invalid(rejectionMessage);
    }
    if (confidence < 0.55) {
      return ImageValidationResult.invalid(
        rejectionMessage,
        details: {'label': label, 'confidence': confidence},
      );
    }

    return ImageValidationResult.valid(details: {
      'label': label,
      'confidence': confidence,
    });
  }

  Future<ImageValidationResult> _checkQuality(File image) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ImageValidationResult.invalid(rejectionMessage);
    }

    final sample = img.copyResize(decoded, width: 96, height: 96);
    final metrics = _metrics(sample);

    if (metrics.brightness < 18 || metrics.brightness > 242) {
      return ImageValidationResult.invalid(
        rejectionMessage,
        details: {'reason': 'brightness', 'value': metrics.brightness},
      );
    }
    if (metrics.contrast < 12) {
      return ImageValidationResult.invalid(
        rejectionMessage,
        details: {'reason': 'contrast', 'value': metrics.contrast},
      );
    }
    if (metrics.sharpness < 8) {
      return ImageValidationResult.invalid(
        rejectionMessage,
        details: {'reason': 'sharpness', 'value': metrics.sharpness},
      );
    }

    return ImageValidationResult.valid(details: {
      'brightness': metrics.brightness,
      'contrast': metrics.contrast,
      'sharpness': metrics.sharpness,
    });
  }

  Future<ImageValidationResult> _checkCropPattern(File image) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ImageValidationResult.invalid(rejectionMessage);
    }

    final sample = img.copyResize(decoded, width: 96, height: 96);
    final signature = _cropSignature(sample);
    final plantLikeRatio = signature.greenRatio + signature.yellowBrownRatio;

    final valid = plantLikeRatio >= 0.06 &&
        signature.saturatedRatio >= 0.06 &&
        signature.neutralRatio <= 0.92 &&
        signature.veryDarkRatio <= 0.82;

    if (!valid) {
      return ImageValidationResult.invalid(
        rejectionMessage,
        details: {
          'reason': 'crop_pattern',
          'greenRatio': signature.greenRatio,
          'yellowBrownRatio': signature.yellowBrownRatio,
          'saturatedRatio': signature.saturatedRatio,
          'neutralRatio': signature.neutralRatio,
          'veryDarkRatio': signature.veryDarkRatio,
        },
      );
    }

    return ImageValidationResult.valid(details: {
      'greenRatio': signature.greenRatio,
      'yellowBrownRatio': signature.yellowBrownRatio,
      'saturatedRatio': signature.saturatedRatio,
      'neutralRatio': signature.neutralRatio,
      'veryDarkRatio': signature.veryDarkRatio,
    });
  }

  _ImageMetrics _metrics(img.Image image) {
    final width = image.width;
    final height = image.height;
    var count = 0;
    var total = 0.0;
    var totalSq = 0.0;
    var edgeSum = 0.0;

    final grayscale = List<double>.filled(width * height, 0.0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final value = (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);
        final index = (y * width) + x;
        grayscale[index] = value;
        total += value;
        totalSq += value * value;
        count++;
      }
    }

    for (var y = 0; y < height - 1; y++) {
      for (var x = 0; x < width - 1; x++) {
        final index = (y * width) + x;
        final dx = (grayscale[index] - grayscale[index + 1]).abs();
        final dy = (grayscale[index] - grayscale[index + width]).abs();
        edgeSum += dx + dy;
      }
    }

    final mean = total / count;
    final variance = (totalSq / count) - (mean * mean);
    final sharpness = edgeSum / ((width - 1) * (height - 1));

    return _ImageMetrics(
      brightness: mean,
      contrast: variance < 0 ? 0 : variance.sqrtApprox(),
      sharpness: sharpness,
    );
  }

  _CropSignature _cropSignature(img.Image image) {
    final total = image.width * image.height;
    var greenCount = 0;
    var yellowBrownCount = 0;
    var neutralCount = 0;
    var saturatedCount = 0;
    var veryDarkCount = 0;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;
        final hsv = _rgbToHsv(r, g, b);

        if (hsv.value < 0.18) veryDarkCount++;
        if (hsv.saturation < 0.12) {
          neutralCount++;
        } else {
          saturatedCount++;
        }

        final hue = hsv.hue;
        if (hsv.saturation >= 0.16 && hsv.value >= 0.16) {
          if (hue >= 35 && hue <= 160) {
            greenCount++;
          } else if (hue >= 12 && hue < 35) {
            yellowBrownCount++;
          }
        }
      }
    }

    return _CropSignature(
      greenRatio: greenCount / total,
      yellowBrownRatio: yellowBrownCount / total,
      neutralRatio: neutralCount / total,
      saturatedRatio: saturatedCount / total,
      veryDarkRatio: veryDarkCount / total,
    );
  }

  _Hsv _rgbToHsv(double r, double g, double b) {
    final max = [r, g, b].reduce((a, b) => a > b ? a : b).toDouble();
    final min = [r, g, b].reduce((a, b) => a < b ? a : b).toDouble();
    final delta = max - min;

    double hue;
    if (delta == 0) {
      hue = 0;
    } else if (max == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (max == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
    if (hue < 0) hue += 360;

    final saturation = max == 0 ? 0.0 : (delta / max).toDouble();
    return _Hsv(hue: hue, saturation: saturation, value: max);
  }
}

class ImageValidationResult {
  final bool valid;
  final String? message;
  final Map<String, dynamic> details;

  const ImageValidationResult._({
    required this.valid,
    this.message,
    this.details = const {},
  });

  const ImageValidationResult.valid({Map<String, dynamic> details = const {}})
      : this._(valid: true, details: details);

  const ImageValidationResult.invalid(
    String message, {
    Map<String, dynamic> details = const {},
  }) : this._(valid: false, message: message, details: details);
}

class _ImageMetrics {
  final double brightness;
  final double contrast;
  final double sharpness;

  const _ImageMetrics({
    required this.brightness,
    required this.contrast,
    required this.sharpness,
  });
}

class _CropSignature {
  final double greenRatio;
  final double yellowBrownRatio;
  final double neutralRatio;
  final double saturatedRatio;
  final double veryDarkRatio;

  const _CropSignature({
    required this.greenRatio,
    required this.yellowBrownRatio,
    required this.neutralRatio,
    required this.saturatedRatio,
    required this.veryDarkRatio,
  });
}

class _Hsv {
  final double hue;
  final double saturation;
  final double value;

  const _Hsv({
    required this.hue,
    required this.saturation,
    required this.value,
  });
}

extension on double {
  double sqrtApprox() {
    if (this <= 0) return 0;
    var x = this;
    var guess = x > 1 ? x / 2 : 1.0;
    for (var i = 0; i < 8; i++) {
      guess = 0.5 * (guess + (x / guess));
    }
    return guess;
  }
}
