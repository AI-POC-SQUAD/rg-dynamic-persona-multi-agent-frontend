class PersonaData {
  final int id;
  final String name;
  final String description;
  final String backgroundAsset;
  final String sphereAsset;

  PersonaData({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundAsset,
    required this.sphereAsset,
  });

  /// Get the backend persona name for API calls
  String get backendPersonaName {
    switch (id) {
      case 0:
        return 'ev_skeptic_traditionalists_base';
      case 1:
        return 'environment_evangelists_base';
      case 2:
        return 'price_conscious_errand_drivers_base';
      case 3:
        return 'status_driven_commuters_base';
      case 4:
        return 'convenience_buyers_base';
      default:
        return 'convenience_buyers_base'; // fallback
    }
  }

  static List<PersonaData> getPersonas() {
    return [
      PersonaData(
        id: 0,
        name: 'EV Skeptic',
        description:
            '"I do not trust EVs and want longer ranges before I switch"',
        backgroundAsset: 'assets/images/persona_0.png',
        sphereAsset: 'assets/images/sphere_0.png',
      ),
      PersonaData(
        id: 1,
        name: 'Environment evangelists',
        description:
            '"My life evolves around the environment, so an EV is the logical choice for a car"',
        backgroundAsset: 'assets/images/persona_1.png',
        sphereAsset: 'assets/images/sphere_1.png',
      ),
      PersonaData(
        id: 2,
        name: 'Price-conscious errand drivers',
        description:
            '"EVs are the right thing for the environment but too expensive for me"',
        backgroundAsset: 'assets/images/persona_2.png',
        sphereAsset: 'assets/images/sphere_2.png',
      ),
      PersonaData(
        id: 3,
        name: 'Status-driven commuters',
        description:
            '"I want to own an EV because of the status and the technology"',
        backgroundAsset: 'assets/images/persona_3.png',
        sphereAsset: 'assets/images/sphere_3.png',
      ),
      PersonaData(
        id: 4,
        name: 'Convenience buyers',
        description:
            '"I’ll switch to EVs if I can integrate it seamlessly into my life"',
        backgroundAsset: 'assets/images/persona_4.png',
        sphereAsset: 'assets/images/sphere_4.png',
      ),
    ];
  }
}
