class ResidueModel {
  final String id, residueType, moistureLevel, bestOption, imageUrl;
  final double estimatedQuantityKg, projectedEarnings;
  final Map<String, double> allOptions;
  final DateTime analyzedAt;

  const ResidueModel(
      {required this.id,
      required this.residueType,
      required this.moistureLevel,
      required this.bestOption,
      required this.imageUrl,
      required this.estimatedQuantityKg,
      required this.projectedEarnings,
      required this.allOptions,
      required this.analyzedAt});

  factory ResidueModel.fromJson(Map<String, dynamic> j) => ResidueModel(
        id: j['id']?.toString() ?? '',
        residueType: j['residue_type'] ?? '',
        moistureLevel: j['moisture_level'] ?? '',
        bestOption: j['best_option'] ?? '',
        imageUrl: j['image_url'] ?? '',
        estimatedQuantityKg:
            (j['estimated_quantity_kg'] as num? ?? 0).toDouble(),
        projectedEarnings: (j['projected_earnings'] as num? ?? 0).toDouble(),
        allOptions: Map<String, double>.from((j['all_options'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))),
        analyzedAt: DateTime.tryParse(j['analyzed_at'] ?? '') ?? DateTime.now(),
      );
}
