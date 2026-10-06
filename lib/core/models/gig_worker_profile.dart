import 'kyc_document.dart';
import 'skill.dart';

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
