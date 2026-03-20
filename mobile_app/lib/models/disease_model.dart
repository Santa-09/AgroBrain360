class DiseaseModel {
  final String id,
      diseaseName,
      cropType,
      severity,
      description,
      treatmentPlan,
      imageUrl;
  final double confidence, treatmentCost, estimatedLoss;
  final List<String> symptoms;
  final DateTime scannedAt;

  const DiseaseModel(
      {required this.id,
      required this.diseaseName,
      required this.cropType,
      required this.severity,
      required this.description,
      required this.treatmentPlan,
      required this.imageUrl,
      required this.confidence,
      required this.treatmentCost,
      required this.estimatedLoss,
      required this.symptoms,
      required this.scannedAt});

  bool get isHealthy => diseaseName.toLowerCase().contains('healthy');
  double get savings =>
      (estimatedLoss - treatmentCost).clamp(0, double.infinity);

  factory DiseaseModel.fromJson(Map<String, dynamic> j) => DiseaseModel(
        id: j['id']?.toString() ?? '',
        diseaseName: j['disease_name'] ?? 'Unknown',
        cropType: j['crop_type'] ?? '',
        severity: j['severity'] ?? 'low',
        description: j['description'] ?? '',
        treatmentPlan: j['treatment_plan'] ?? '',
        imageUrl: j['image_url'] ?? '',
        confidence: (j['confidence'] as num? ?? 0).toDouble(),
        treatmentCost: (j['treatment_cost'] as num? ?? 0).toDouble(),
        estimatedLoss: (j['estimated_loss'] as num? ?? 0).toDouble(),
        symptoms: List<String>.from(j['symptoms'] ?? []),
        scannedAt: DateTime.tryParse(j['scanned_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'disease_name': diseaseName,
        'crop_type': cropType,
        'severity': severity,
        'description': description,
        'treatment_plan': treatmentPlan,
        'image_url': imageUrl,
        'confidence': confidence,
        'treatment_cost': treatmentCost,
        'estimated_loss': estimatedLoss,
        'symptoms': symptoms,
        'scanned_at': scannedAt.toIso8601String(),
      };
}
