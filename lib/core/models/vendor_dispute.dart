class DisputeCategory {
  const DisputeCategory({required this.key, required this.label});

  final String key;
  final String label;

  factory DisputeCategory.fromJson(Map<String, dynamic> json) =>
      DisputeCategory(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

class VendorDispute {
  const VendorDispute({
    required this.id,
    required this.reference,
    required this.type,
    required this.category,
    required this.categoryLabel,
    required this.subject,
    required this.description,
    required this.status,
    required this.messageCount,
    required this.canReply,
    required this.canClose,
    required this.messages,
    this.bookingLabel,
    this.resolution,
  });

  final String id;
  final String reference;
  final String type;
  final String category;
  final String categoryLabel;
  final String subject;
  final String description;
  final String status;
  final int messageCount;
  final bool canReply;
  final bool canClose;
  final String? bookingLabel;
  final String? resolution;
  final List<DisputeMessage> messages;

  factory VendorDispute.fromJson(Map<String, dynamic> json) {
    final actions = json['actions'] as Map<String, dynamic>? ?? const {};
    final booking = json['booking'] as Map<String, dynamic>?;
    final service = booking?['service'] as Map<String, dynamic>?;
    final bookingNumber = booking?['bookingNumber']?.toString();
    final serviceName = service?['name']?.toString();
    return VendorDispute(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DISPUTE',
      category: json['category']?.toString() ?? '',
      categoryLabel: json['categoryLabel']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      canReply: actions['canReply'] == true,
      canClose: actions['canClose'] == true,
      bookingLabel:
          [bookingNumber, serviceName].whereType<String>().join(' · ').isEmpty
          ? null
          : [bookingNumber, serviceName].whereType<String>().join(' · '),
      resolution: json['resolution']?.toString(),
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DisputeMessage.fromJson)
          .toList(growable: false),
    );
  }
}

class DisputeMessage {
  const DisputeMessage({
    required this.id,
    required this.body,
    required this.authorName,
    required this.mine,
  });

  final String id;
  final String body;
  final String authorName;
  final bool mine;

  factory DisputeMessage.fromJson(Map<String, dynamic> json) => DisputeMessage(
    id: json['id']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    authorName: json['authorName']?.toString() ?? 'Support',
    mine: json['mine'] == true,
  );
}
