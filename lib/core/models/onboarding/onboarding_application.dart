

import 'onboarding_bank_details.dart';
import 'onboarding_document.dart';
import 'onboarding_flow.dart';
import 'onboarding_personal_details.dart';
import 'onboarding_profile_photo.dart';
import 'onboarding_services.dart';
import 'onboarding_user.dart';

class DetailStep {
  final String key;
  final bool complete;

  DetailStep({required this.key, required this.complete});

  factory DetailStep.fromJson(Map<String, dynamic> json) {
    return DetailStep(
      key: json['key'] as String,
      complete: json['complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'key': key, 'complete': complete};
  }
}

class OnboardingApplication {
  final String? id;
  final String? status;
  final OnboardingFlow? flow;
  final String? reviewNote;
  final String? submittedAt;
  final String? reviewedAt;
  final List<DetailStep>? detailSteps;
  final String? nextStep;
  final bool? canSubmit;
  final bool? isEditable;
  final OnboardingUser? user;
  final List<OnboardingDocument>? documents;
  final OnboardingBankDetails? bankDetails;
  final OnboardingPersonalDetails? personalDetails;
  final OnboardingServices? services;
  final OnboardingProfilePhoto? profilePhoto;

  OnboardingApplication({
    this.id,
    this.status,
    this.flow,
    this.reviewNote,
    this.submittedAt,
    this.reviewedAt,
    this.detailSteps,
    this.nextStep,
    this.canSubmit,
    this.isEditable,
    this.user,
    this.documents,
    this.bankDetails,
    this.personalDetails,
    this.services,
    this.profilePhoto,
  });

  factory OnboardingApplication.fromJson(Map<String, dynamic> json) {
    final docsList = (json['documents'] as List<dynamic>? ?? <dynamic>[])
        .map((d) => OnboardingDocument.fromJson(d as Map<String, dynamic>))
        .toList();
    final detailStepsList =
        (json['detailSteps'] as List<dynamic>? ?? <dynamic>[])
            .map((d) => DetailStep.fromJson(d as Map<String, dynamic>))
            .toList();
    return OnboardingApplication(
      id: json['id'] as String?,
      status: json['status'] as String?,
      flow: json['flow'] != null
          ? OnboardingFlow.fromJson(json['flow'] as Map<String, dynamic>)
          : null,
      reviewNote: json['reviewNote'] as String?,
      submittedAt: json['submittedAt'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      detailSteps: detailStepsList,
      nextStep: json['nextStep'] as String?,
      canSubmit: json['canSubmit'] as bool? ?? false,
      isEditable: json['isEditable'] as bool? ?? true,
      user: json['user'] != null
          ? OnboardingUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      documents: docsList,
      bankDetails: json['bankDetails'] != null
          ? OnboardingBankDetails.fromJson(
              json['bankDetails'] as Map<String, dynamic>)
          : null,
      personalDetails: json['personalDetails'] != null
          ? OnboardingPersonalDetails.fromJson(
              json['personalDetails'] as Map<String, dynamic>)
          : null,
      services: json['services'] != null
          ? OnboardingServices.fromJson(
              json['services'] as Map<String, dynamic>)
          : null,
      profilePhoto: json['profilePhoto'] != null
          ? OnboardingProfilePhoto.fromJson(
              json['profilePhoto'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (flow != null) 'flow': flow!.toJson(),
      if (reviewNote != null) 'reviewNote': reviewNote,
      if (submittedAt != null) 'submittedAt': submittedAt,
      if (reviewedAt != null) 'reviewedAt': reviewedAt,
      if (detailSteps != null)
        'detailSteps': detailSteps!.map((d) => d.toJson()).toList(),
      if (nextStep != null) 'nextStep': nextStep,
      if (canSubmit != null) 'canSubmit': canSubmit,
      if (isEditable != null) 'isEditable': isEditable,
      if (user != null) 'user': user!.toJson(),
      if (documents != null)
        'documents': documents!.map((d) => d.toJson()).toList(),
      if (bankDetails != null) 'bankDetails': bankDetails!.toJson(),
      if (personalDetails != null)
        'personalDetails': personalDetails!.toJson(),
      if (services != null) 'services': services!.toJson(),
      if (profilePhoto != null) 'profilePhoto': profilePhoto!.toJson(),
    };
  }
}
