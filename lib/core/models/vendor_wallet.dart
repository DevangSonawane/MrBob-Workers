class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.onHold,
    required this.readyForPayout,
    required this.totalPaidOut,
    required this.totalEarned,
    this.holdLabel,
    this.nextPayoutDate,
    this.nextReleaseAt,
    this.nextReleaseAmount,
  });

  final num balance;
  final num onHold;
  final num readyForPayout;
  final num totalPaidOut;
  final num totalEarned;
  final String? holdLabel;
  final DateTime? nextPayoutDate;
  final DateTime? nextReleaseAt;
  final num? nextReleaseAmount;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final release = json['nextRelease'] as Map<String, dynamic>?;
    return WalletSummary(
      balance: _number(json['balance']),
      onHold: _number(json['onHold']),
      readyForPayout: _number(json['readyForPayout']),
      totalPaidOut: _number(json['totalPaidOut']),
      totalEarned: _number(json['totalEarned']),
      holdLabel: json['holdLabel']?.toString(),
      nextPayoutDate: DateTime.tryParse(
        json['nextPayoutDate']?.toString() ?? '',
      ),
      nextReleaseAt: DateTime.tryParse(release?['at']?.toString() ?? ''),
      nextReleaseAmount: release == null ? null : _number(release['amount']),
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.availableAt,
  });

  final String id;
  final String title;
  final num amount;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? availableAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Wallet transaction',
        amount: _number(json['amount']),
        type: json['type']?.toString() ?? 'EARNING',
        status: json['status']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        availableAt: DateTime.tryParse(json['availableAt']?.toString() ?? ''),
      );
}

class PendingWalletEarnings {
  const PendingWalletEarnings({
    required this.items,
    required this.pending,
    required this.onHold,
    required this.readyForPayout,
  });

  final List<WalletTransaction> items;
  final num pending;
  final num onHold;
  final num readyForPayout;

  factory PendingWalletEarnings.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    return PendingWalletEarnings(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WalletTransaction.fromJson)
          .toList(growable: false),
      pending: _number(totals['pending']),
      onHold: _number(totals['onHold']),
      readyForPayout: _number(totals['readyForPayout']),
    );
  }
}

class PayoutAccount {
  const PayoutAccount({
    required this.status,
    required this.hasBankAccount,
    required this.hasUpi,
    this.accountHolderName,
    this.maskedAccountNumber,
    this.ifsc,
    this.bankName,
    this.branchName,
    this.accountType,
    this.upiId,
  });

  final String status;
  final bool hasBankAccount;
  final bool hasUpi;
  final String? accountHolderName;
  final String? maskedAccountNumber;
  final String? ifsc;
  final String? bankName;
  final String? branchName;
  final String? accountType;
  final String? upiId;

  bool get isVerified =>
      const {'VERIFIED', 'APPROVED', 'ACTIVE'}.contains(status);

  factory PayoutAccount.fromJson(Map<String, dynamic> json) {
    final nestedAccount = json['payoutAccount'] ?? json['account'];
    final data = nestedAccount is Map<String, dynamic> ? nestedAccount : json;
    final verificationStatus = data['verificationStatus'] ?? data['status'];
    return PayoutAccount(
      status: verificationStatus?.toString().trim().toUpperCase() ?? 'PENDING',
      hasBankAccount: data['hasBankAccount'] == true,
      hasUpi: data['hasUpi'] == true,
      accountHolderName: data['accountHolderName']?.toString(),
      maskedAccountNumber: data['maskedAccountNumber']?.toString(),
      ifsc: data['ifsc']?.toString(),
      bankName: data['bankName']?.toString(),
      branchName: data['branchName']?.toString(),
      accountType: data['accountType']?.toString(),
      upiId: data['upiId']?.toString(),
    );
  }
}

num _number(Object? value) =>
    value is num ? value : num.tryParse('$value') ?? 0;
