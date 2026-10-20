class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresIn:
          (json['accessTokenExpiresIn'] as num?)?.toInt() ?? 900,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresIn': accessTokenExpiresIn,
    };
  }
}
