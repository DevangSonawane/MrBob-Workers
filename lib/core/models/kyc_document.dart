enum KycDocType { aadhar, pan }

enum KycStatus { notStarted, inProgress, submitted, verifying, verified, rejected }

class KycDocument {
  const KycDocument({
    required this.type,
    required this.number,
    required this.holderName,
    required this.dob,
    this.imagePath,
  });

  final KycDocType type;

  /// Aadhar: 12 digits. PAN: 10-char alphanumeric (AAAAA9999A).
  final String number;
  final String holderName;

  /// 'DD/MM/YYYY'.
  final String dob;

  /// Local path after the simulated "scan".
  final String? imagePath;

  String get label => type == KycDocType.aadhar ? 'Aadhar Card' : 'PAN Card';

  /// Masked number for display: Aadhar → '•••• •••• 9012', PAN → 'AB•••••F'.
  String get maskedNumber {
    if (type == KycDocType.aadhar) {
      final digits = number.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 4) return '•••• •••• ••••';
      return '•••• •••• ${digits.substring(digits.length - 4)}';
    }
    if (number.length < 3) return '••••••••••';
    return '${number.substring(0, 2)}•••••${number.substring(number.length - 1)}';
  }
}
