class CustomerSegment {
  final String id;
  final String name;
  final String description;
  final bool isSelected;
  final String iconPath;

  const CustomerSegment({
    required this.id,
    required this.name,
    required this.description,
    this.isSelected = false,
    required this.iconPath,
  });

  CustomerSegment copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSelected,
    String? iconPath,
  }) {
    return CustomerSegment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSelected: isSelected ?? this.isSelected,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  static List<CustomerSegment> getDefaultSegments() {
    return [
      const CustomerSegment(
        id: 'ev_sceptic',
        name: 'EV Sceptic',
        description: 'Customers who are skeptical about electric vehicles',
        iconPath: 'assets/images/sphere_0.png',
      ),
      const CustomerSegment(
        id: 'status_driven',
        name: 'Status-driven commuters',
        description: 'Customers focused on status and prestige in commuting',
        iconPath: 'assets/images/sphere_3.png',
      ),
      const CustomerSegment(
        id: 'environment_evangelists',
        name: 'Environment evangelists',
        description:
            'Environmentally conscious customers promoting green solutions',
        iconPath: 'assets/images/sphere_1.png',
      ),
      const CustomerSegment(
        id: 'price_conscious',
        name: 'Price-conscious errand drivers',
        description: 'Budget-focused customers for daily errands',
        iconPath: 'assets/images/sphere_2.png',
      ),
      const CustomerSegment(
        id: 'convenience_buyers',
        name: 'Convenience buyers',
        description: 'Customers prioritizing convenience and ease of use',
        iconPath: 'assets/images/sphere_4.png',
      ),
    ];
  }
}
