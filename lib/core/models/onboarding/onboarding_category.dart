

class OnboardingCategory {
  final String id;
  final String name;

  OnboardingCategory({required this.id, required this.name});

  factory OnboardingCategory.fromJson(Map<String, dynamic> json) {
    return OnboardingCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name};
  }
}
