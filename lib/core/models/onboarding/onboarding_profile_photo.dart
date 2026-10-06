

class OnboardingProfilePhoto {
  final String? url;

  OnboardingProfilePhoto({this.url});

  factory OnboardingProfilePhoto.fromJson(Map<String, dynamic> json) {
    return OnboardingProfilePhoto(url: json['url'] as String?);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{if (url != null) 'url': url};
  }
}
