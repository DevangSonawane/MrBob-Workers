

class OnboardingZone {
  final String id;
  final String name;
  final String? cityId;

  OnboardingZone({required this.id, required this.name, this.cityId});

  factory OnboardingZone.fromJson(Map<String, dynamic> json) {
    return OnboardingZone(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cityId: json['cityId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (cityId != null) 'cityId': cityId,
    };
  }
}
