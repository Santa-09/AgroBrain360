class FHIModel {
  final String id, label;
  final int overall, crop, soil, water, livestock, machinery;
  final List<String> recommendations;
  final DateTime updatedAt;

  const FHIModel(
      {required this.id,
      required this.label,
      required this.overall,
      required this.crop,
      required this.soil,
      required this.water,
      required this.livestock,
      required this.machinery,
      required this.recommendations,
      required this.updatedAt});

  factory FHIModel.empty() => FHIModel(
      id: '',
      label: 'No Data',
      overall: 0,
      crop: 0,
      soil: 0,
      water: 0,
      livestock: 0,
      machinery: 0,
      recommendations: [],
      updatedAt: DateTime.now());

  factory FHIModel.fromJson(Map<String, dynamic> j) => FHIModel(
        id: j['id']?.toString() ?? '',
        label: j['label'] ?? '',
        overall: (j['overall_score'] as num? ?? 0).toInt(),
        crop: (j['crop_score'] as num? ?? 0).toInt(),
        soil: (j['soil_score'] as num? ?? 0).toInt(),
        water: (j['water_score'] as num? ?? 0).toInt(),
        livestock: (j['livestock_score'] as num? ?? 0).toInt(),
        machinery: (j['machinery_score'] as num? ?? 0).toInt(),
        recommendations: List<String>.from(j['recommendations'] ?? []),
        updatedAt: DateTime.tryParse(j['updated_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'overall_score': overall,
        'crop_score': crop,
        'soil_score': soil,
        'water_score': water,
        'livestock_score': livestock,
        'machinery_score': machinery,
        'recommendations': recommendations,
        'updated_at': updatedAt.toIso8601String(),
      };
}
