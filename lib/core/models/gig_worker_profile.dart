import 'kyc_document.dart';
import 'skill.dart';
import '../data/skills_data.dart';

class GigWorkerProfile {
  const GigWorkerProfile({
    this.name = '',
    this.phone = '',
    this.gender = 'Male',
    this.serviceArea = '',
    this.latitude = 19.2836,
    this.longitude = 72.8727,
    this.skills = const <Skill>[],
    this.kycStatus = KycStatus.notStarted,
    this.kycDocument,
  });

  final String name;
  final String phone;
  final String gender;
  final String serviceArea;

  /// Worker's current (demo-fixed) location — Andheri East, Mumbai.
  final double latitude;
  final double longitude;
  final List<Skill> skills;
  final KycStatus kycStatus;
  final KycDocument? kycDocument;

  bool get isKycVerified => kycStatus == KycStatus.verified;

  factory GigWorkerProfile.fromJson(Map<String, dynamic> json) {
    final serviceArea = _readString(json, const [
      'serviceArea',
      'service_area',
      'area',
      'address',
      'city',
      'zoneName',
    ]);
    final latitude = _readDouble(json, const ['latitude', 'lat']) ?? 19.2836;
    final longitude =
        _readDouble(json, const ['longitude', 'lng', 'lon']) ?? 72.8727;
    final rawSkills = json['skills'] ?? json['services'] ?? json['categories'];

    return GigWorkerProfile(
      name: _readString(json, const ['name', 'fullName', 'full_name']) ?? '',
      phone: _readString(json, const ['phone', 'mobile', 'phoneNumber']) ?? '',
      gender: _readString(json, const ['gender']) ?? 'Male',
      serviceArea: serviceArea ?? '',
      latitude: latitude,
      longitude: longitude,
      skills: _parseSkills(rawSkills),
      kycStatus: _parseKycStatus(
        _readString(json, const ['kycStatus', 'kyc_status', 'status']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'phone': phone,
      'gender': gender,
      'serviceArea': serviceArea,
      'latitude': latitude,
      'longitude': longitude,
      'skills': skills.map((skill) => skill.id).toList(),
    };
  }

  GigWorkerProfile copyWith({
    String? name,
    String? phone,
    String? gender,
    String? serviceArea,
    double? latitude,
    double? longitude,
    List<Skill>? skills,
    KycStatus? kycStatus,
    KycDocument? kycDocument,
    bool clearKycDocument = false,
  }) {
    return GigWorkerProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      serviceArea: serviceArea ?? this.serviceArea,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      skills: skills ?? this.skills,
      kycStatus: kycStatus ?? this.kycStatus,
      kycDocument: clearKycDocument ? null : (kycDocument ?? this.kycDocument),
    );
  }
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
}

List<Skill> _parseSkills(Object? rawSkills) {
  if (rawSkills is! List) return const <Skill>[];
  return rawSkills
      .map((raw) {
        if (raw is Map<String, dynamic>) {
          final id =
              _readString(raw, const ['id', '_id', 'slug', 'categoryId']) ?? '';
          final nestedId = raw['category'] is Map<String, dynamic>
              ? _readString(raw['category'] as Map<String, dynamic>, const [
                  'id',
                  '_id',
                  'slug',
                ])
              : null;
          return skillById(nestedId ?? id);
        }
        return skillById(raw.toString());
      })
      .toList(growable: false);
}

KycStatus _parseKycStatus(String? rawStatus) {
  final normalized = (rawStatus ?? '').toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  return switch (normalized) {
    'inprogress' => KycStatus.inProgress,
    'submitted' => KycStatus.submitted,
    'verifying' || 'pending' || 'underreview' => KycStatus.verifying,
    'verified' || 'approved' => KycStatus.verified,
    'rejected' || 'failed' => KycStatus.rejected,
    _ => KycStatus.notStarted,
  };
}
