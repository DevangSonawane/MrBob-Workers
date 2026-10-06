

class OnboardingCity {
  final String id;
  final String name;

  OnboardingCity({required this.id, required this.name});

  factory OnboardingCity.fromJson(Map<String, dynamic> json) {
    return OnboardingCity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name};
  }
}
