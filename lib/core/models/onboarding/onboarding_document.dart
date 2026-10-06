

class OnboardingDocument {
  final String type;
  final String status;
  final String? maskedNumber;
  final String? nameOnDocument;
  final String? rejectionReason;
  final Map<String, String>? files;

  OnboardingDocument({
    required this.type,
    required this.status,
    this.maskedNumber,
    this.nameOnDocument,
    this.rejectionReason,
    this.files,
  });

  factory OnboardingDocument.fromJson(Map<String, dynamic> json) {
    final filesMap = json['files'] != null
        ? Map<String, String>.from(json['files'] as Map)
        : null;
    return OnboardingDocument(
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'NOT_UPLOADED',
      maskedNumber: json['maskedNumber'] as String?,
      nameOnDocument: json['nameOnDocument'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      files: filesMap,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'status': status,
      if (maskedNumber != null) 'maskedNumber': maskedNumber,
      if (nameOnDocument != null) 'nameOnDocument': nameOnDocument,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (files != null) 'files': files,
    };
  }
}
