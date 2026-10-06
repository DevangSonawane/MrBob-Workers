

class OnboardingBankDetails {
  final String status;
  final String? maskedAccountNumber;
  final String? ifsc;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? accountType;
  final String? branchName;
  final String? upiId;
  final String? proofFile;

  OnboardingBankDetails({
    required this.status,
    this.maskedAccountNumber,
    this.ifsc,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.accountType,
    this.branchName,
    this.upiId,
    this.proofFile,
  });

  factory OnboardingBankDetails.fromJson(Map<String, dynamic> json) {
    return OnboardingBankDetails(
      status: json['status'] as String? ?? 'NOT_UPLOADED',
      maskedAccountNumber: json['maskedAccountNumber'] as String?,
      ifsc: json['ifsc'] as String?,
      bankName: json['bankName'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      accountType: json['accountType'] as String?,
      branchName: json['branchName'] as String?,
      upiId: json['upiId'] as String?,
      proofFile: json['proofFile'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status,
      if (maskedAccountNumber != null)
        'maskedAccountNumber': maskedAccountNumber,
      if (ifsc != null) 'ifsc': ifsc,
      if (bankName != null) 'bankName': bankName,
      if (accountHolderName != null)
        'accountHolderName': accountHolderName,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (accountType != null) 'accountType': accountType,
      if (branchName != null) 'branchName': branchName,
      if (upiId != null) 'upiId': upiId,
      if (proofFile != null) 'proofFile': proofFile,
    };
  }
}
