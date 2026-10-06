

class OnboardingUser {
  final String? id;
  final String? name;
  final String? phone;
  final String? role;
  final bool? isOnboarded;

  OnboardingUser({
    this.id,
    this.name,
    this.phone,
    this.role,
    this.isOnboarded,
  });

  factory OnboardingUser.fromJson(Map<String, dynamic> json) {
    return OnboardingUser(
      id: json['id'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      isOnboarded: json['isOnboarded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (isOnboarded != null) 'isOnboarded': isOnboarded,
    };
  }

  OnboardingUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    bool? isOnboarded,
  }) {
    return OnboardingUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}
