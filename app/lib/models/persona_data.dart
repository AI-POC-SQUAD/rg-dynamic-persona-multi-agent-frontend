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

  static List<PersonaData> getPersonas() {
    return [
      PersonaData(
        id: 0,
        name: 'EV Skeptic',
        description:
            'I drive an EV for environmental reasons, what matters to me is its positive impact. I use my car sparingly, for considered trips.',
        backgroundAsset: 'assets/images/persona_0.png',
        sphereAsset: 'assets/images/sphere_0.png',
      ),
      PersonaData(
        id: 1,
        name: 'Environment evangelists',
        description:
            'I drive an EV for environmental reasons, what matters to me is its positive impact. I use my car sparingly, for considered trips.',
        backgroundAsset: 'assets/images/persona_1.png',
        sphereAsset: 'assets/images/sphere_1.png',
      ),
      PersonaData(
        id: 2,
        name: 'Price-conscious errand drivers',
        description:
            'I drive an EV for environmental reasons, what matters to me is its positive impact. I use my car sparingly, for considered trips.',
        backgroundAsset: 'assets/images/persona_2.png',
        sphereAsset: 'assets/images/sphere_2.png',
      ),
      PersonaData(
        id: 3,
        name: 'Status-driven commuters',
        description:
            'I drive an EV for environmental reasons, what matters to me is its positive impact. I use my car sparingly, for considered trips.',
        backgroundAsset: 'assets/images/persona_3.png',
        sphereAsset: 'assets/images/sphere_3.png',
      ),
      PersonaData(
        id: 4,
        name: 'Convenience buyers',
        description:
            'I drive an EV for environmental reasons, what matters to me is its positive impact. I use my car sparingly, for considered trips.',
        backgroundAsset: 'assets/images/persona_4.png',
        sphereAsset: 'assets/images/sphere_4.png',
      ),
    ];
  }
}
