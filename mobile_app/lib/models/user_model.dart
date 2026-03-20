class UserModel {
  final String id, name, phone, language;
  final String? token, location;
  final DateTime createdAt;

  const UserModel(
      {required this.id,
      required this.name,
      required this.phone,
      required this.language,
      this.token,
      this.location,
      required this.createdAt});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        language: j['language'] ?? 'en',
        token: j['token'],
        location: j['location'],
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'language': language,
        'token': token,
        'location': location,
        'created_at': createdAt.toIso8601String(),
      };
}
