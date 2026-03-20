class CropModel {
  final String id, name, scientificName, season;
  final List<String> commonDiseases;
  const CropModel(
      {required this.id,
      required this.name,
      required this.scientificName,
      required this.season,
      required this.commonDiseases});
  factory CropModel.fromJson(Map<String, dynamic> j) => CropModel(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        scientificName: j['scientific_name'] ?? '',
        season: j['season'] ?? '',
        commonDiseases: List<String>.from(j['common_diseases'] ?? []),
      );
}
