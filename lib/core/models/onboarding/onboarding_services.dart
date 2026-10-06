

class OnboardingServices {
  final List<String> categories;
  final int experienceYears;
  final String? homeZoneId;

  OnboardingServices({
    required this.categories,
    required this.experienceYears,
    this.homeZoneId,
  });

  factory OnboardingServices.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>? ?? <dynamic>[])
        .map((c) => c as String)
        .toList();
    return OnboardingServices(
      categories: cats,
      experienceYears: json['experienceYears'] as int? ?? 0,
      homeZoneId: json['homeZoneId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'categories': categories,
      'experienceYears': experienceYears,
      if (homeZoneId != null && homeZoneId!.isNotEmpty)
        'homeZoneId': homeZoneId,
    };
  }

  OnboardingServices copyWith({
    List<String>? categories,
    int? experienceYears,
    String? homeZoneId,
  }) {
    return OnboardingServices(
      categories: categories ?? this.categories,
      experienceYears: experienceYears ?? this.experienceYears,
      homeZoneId: homeZoneId ?? this.homeZoneId,
    );
  }
}
