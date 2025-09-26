import 'persona_data.dart';

/// Represents a persona instance with its specific configuration settings
/// for focus group discussions. Allows multiple instances of the same persona
/// with different settings.
class PersonaInstance {
  /// Unique identifier for this persona instance
  final String id;

  /// The base persona data
  final PersonaData persona;

  /// Housing condition setting (1-8 range)
  final double housingCondition;

  /// Income setting (1-13 range)
  final double income;

  /// Population setting (1-5 range)
  final double population;

  /// Age setting (1-10 range)
  final double age;

  /// Timestamp when this instance was created
  final DateTime createdAt;

  PersonaInstance({
    required this.id,
    required this.persona,
    required this.housingCondition,
    required this.income,
    required this.population,
    required this.age,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this instance with updated settings
  PersonaInstance copyWith({
    String? id,
    PersonaData? persona,
    double? housingCondition,
    double? income,
    double? population,
    double? age,
    DateTime? createdAt,
  }) {
    return PersonaInstance(
      id: id ?? this.id,
      persona: persona ?? this.persona,
      housingCondition: housingCondition ?? this.housingCondition,
      income: income ?? this.income,
      population: population ?? this.population,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Creates a PersonaInstance from the current slider settings
  factory PersonaInstance.fromSettings({
    required PersonaData persona,
    required double housingCondition,
    required double income,
    required double population,
    required double age,
  }) {
    // Generate unique ID using persona ID, timestamp, and settings hash
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final settingsHash =
        '${housingCondition.toInt()}-${income.toInt()}-${population.toInt()}-${age.toInt()}';
    final id = '${persona.id}_${timestamp}_$settingsHash';

    return PersonaInstance(
      id: id,
      persona: persona,
      housingCondition: housingCondition,
      income: income,
      population: population,
      age: age,
    );
  }

  /// Returns a human-readable summary of the settings
  String get settingsSummary {
    return 'Housing: ${housingCondition.toInt()}/8, '
        'Income: ${income.toInt()}/13, '
        'Population: ${population.toInt()}/5, '
        'Age: ${age.toInt()}/10';
  }

  /// Returns a short description for display
  String get displayName {
    return '${persona.name} (${_getShortSettings()})';
  }

  String _getShortSettings() {
    return 'H${housingCondition.toInt()} I${income.toInt()} P${population.toInt()} A${age.toInt()}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonaInstance && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PersonaInstance(id: $id, persona: ${persona.name}, settings: $settingsSummary)';
  }
}
