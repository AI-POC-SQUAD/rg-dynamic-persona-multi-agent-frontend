class PersonaData {
  final String id;
  final String name;
  final String description;

  const PersonaData({
    required this.id,
    required this.name,
    required this.description,
  });

  /// Backend persona identifier exposed by the API
  String get backendPersonaName => id;

  factory PersonaData.fromJson(Map<String, dynamic> json) {
    return PersonaData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown persona',
      description: json['description']?.toString() ?? '',
    );
  }
}
