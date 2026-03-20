class FertilizerRecommendation {
  final String fertilizer;
  final double confidence;
  final String summary;
  final String applicationTip;
  final List<FertilizerRecommendationOption> topRecommendations;

  const FertilizerRecommendation({
    required this.fertilizer,
    required this.confidence,
    required this.summary,
    required this.applicationTip,
    required this.topRecommendations,
  });

  factory FertilizerRecommendation.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return FertilizerRecommendation(
      fertilizer: data['fertilizer']?.toString() ?? 'Unknown',
      confidence: (data['confidence'] as num? ?? 0).toDouble(),
      summary: data['summary']?.toString() ?? '',
      applicationTip: data['application_tip']?.toString() ?? '',
      topRecommendations: ((data['top_recommendations'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => FertilizerRecommendationOption.fromJson(
              Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class FertilizerRecommendationOption {
  final String fertilizer;
  final double confidence;

  const FertilizerRecommendationOption({
    required this.fertilizer,
    required this.confidence,
  });

  factory FertilizerRecommendationOption.fromJson(Map<String, dynamic> json) {
    return FertilizerRecommendationOption(
      fertilizer: json['fertilizer']?.toString() ?? 'Unknown',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
    );
  }
}
