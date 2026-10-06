class OtpRequestResponse {
  final bool sent;
  final int expiresInSeconds;

  OtpRequestResponse({required this.sent, required this.expiresInSeconds});

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      sent: json['sent'] as bool? ?? false,
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 300,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sent': sent,
      'expiresInSeconds': expiresInSeconds,
    };
  }
}
