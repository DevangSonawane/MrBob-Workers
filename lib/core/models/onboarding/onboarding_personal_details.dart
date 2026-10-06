

class OnboardingPersonalDetails {
  final String name;
  final String dateOfBirth;
  final String gender;
  final String cityId;
  final String addressLine1;
  final String? addressLine2;
  final String pincode;
  final String state;
  final String? email;
  final String? alternatePhone;
  final String? landmark;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  OnboardingPersonalDetails({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.cityId,
    required this.addressLine1,
    this.addressLine2,
    required this.pincode,
    required this.state,
    this.email,
    this.alternatePhone,
    this.landmark,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory OnboardingPersonalDetails.fromJson(Map<String, dynamic> json) {
    return OnboardingPersonalDetails(
      name: json['name'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      cityId: json['cityId'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ?? '',
      addressLine2: json['addressLine2'] as String?,
      pincode: json['pincode'] as String? ?? '',
      state: json['state'] as String? ?? '',
      email: json['email'] as String?,
      alternatePhone: json['alternatePhone'] as String?,
      landmark: json['landmark'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'cityId': cityId,
      'addressLine1': addressLine1,
      'pincode': pincode,
      'state': state,
    };
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      map['addressLine2'] = addressLine2;
    }
    if (email != null && email!.isNotEmpty) map['email'] = email;
    if (alternatePhone != null && alternatePhone!.isNotEmpty) {
      map['alternatePhone'] = alternatePhone;
    }
    if (landmark != null && landmark!.isNotEmpty) map['landmark'] = landmark;
    if (emergencyContactName != null && emergencyContactName!.isNotEmpty) {
      map['emergencyContactName'] = emergencyContactName;
    }
    if (emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty) {
      map['emergencyContactPhone'] = emergencyContactPhone;
    }
    return map;
  }

  OnboardingPersonalDetails copyWith({
    String? name,
    String? dateOfBirth,
    String? gender,
    String? cityId,
    String? addressLine1,
    String? addressLine2,
    String? pincode,
    String? state,
    String? email,
    String? alternatePhone,
    String? landmark,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return OnboardingPersonalDetails(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      cityId: cityId ?? this.cityId,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      pincode: pincode ?? this.pincode,
      state: state ?? this.state,
      email: email ?? this.email,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      landmark: landmark ?? this.landmark,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}
