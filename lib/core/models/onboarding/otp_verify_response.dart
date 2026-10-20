import 'onboarding_application.dart';
import 'onboarding_user.dart';

class OtpVerifyResponse {
  final bool isNewUser;
  final OnboardingUser user;
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;
  final OnboardingApplication application;

  OtpVerifyResponse({
    required this.isNewUser,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.application,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      isNewUser: json['isNewUser'] as bool? ?? false,
      user: OnboardingUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresIn:
          (json['accessTokenExpiresIn'] as num?)?.toInt() ?? 900,
      application: OnboardingApplication.fromJson(
        json['application'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isNewUser': isNewUser,
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresIn': accessTokenExpiresIn,
      'application': application.toJson(),
    };
  }
}
