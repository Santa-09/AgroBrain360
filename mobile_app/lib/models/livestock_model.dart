class LivestockModel {
  final String id,
      animalType,
      symptoms,
      diagnosis,
      healthRisk,
      firstAidProtocol,
      nearestVetName,
      nearestVetPhone,
      imageUrl;
  final double riskProbability, nearestVetDistance;
  final List<String> medicines;
  final DateTime diagnosedAt;

  const LivestockModel(
      {required this.id,
      required this.animalType,
      required this.symptoms,
      required this.diagnosis,
      required this.healthRisk,
      required this.firstAidProtocol,
      required this.nearestVetName,
      required this.nearestVetPhone,
      required this.imageUrl,
      required this.riskProbability,
      required this.nearestVetDistance,
      required this.medicines,
      required this.diagnosedAt});

  factory LivestockModel.fromJson(Map<String, dynamic> j) => LivestockModel(
        id: j['id']?.toString() ?? '',
        animalType: j['animal_type'] ?? '',
        symptoms: j['symptoms'] ?? '',
        diagnosis: j['diagnosis'] ?? '',
        healthRisk: j['health_risk'] ?? 'low',
        firstAidProtocol: j['first_aid_protocol'] ?? '',
        nearestVetName: j['nearest_vet_name'] ?? '',
        nearestVetPhone: j['nearest_vet_phone'] ?? '',
        imageUrl: j['image_url'] ?? '',
        riskProbability: (j['risk_probability'] as num? ?? 0).toDouble(),
        nearestVetDistance: (j['nearest_vet_distance'] as num? ?? 0).toDouble(),
        medicines: List<String>.from(j['medicines'] ?? []),
        diagnosedAt:
            DateTime.tryParse(j['diagnosed_at'] ?? '') ?? DateTime.now(),
      );
}
