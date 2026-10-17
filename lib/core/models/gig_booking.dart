import 'skill.dart';
import '../data/skills_data.dart';

enum GigBookingStatus {
  awaitingPayment('Awaiting Payment'),
  pending('Pending'),
  matching('Matching'),
  assigned('Assigned'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const GigBookingStatus(this.label);

  final String label;

  bool get isActive =>
      this == GigBookingStatus.assigned || this == GigBookingStatus.inProgress;
}

enum JobNextStep {
  start('START'),
  verifyCompletionOtp('VERIFY_COMPLETION_OTP'),
  uploadImages('UPLOAD_IMAGES'),
  complete('COMPLETE'),
  none('');

  const JobNextStep(this.value);

  final String value;

  static JobNextStep fromString(String? value) {
    return switch (value?.toUpperCase()) {
      'START' => JobNextStep.start,
      'VERIFY_COMPLETION_OTP' => JobNextStep.verifyCompletionOtp,
      'UPLOAD_IMAGES' => JobNextStep.uploadImages,
      'COMPLETE' => JobNextStep.complete,
      _ => JobNextStep.none,
    };
  }
}

class CompletionImage {
  const CompletionImage({
    required this.id,
    required this.url,
    required this.bookingId,
    required this.createdAt,
  });

  final String id;
  final String url;
  final String bookingId;
  final DateTime createdAt;

  factory CompletionImage.fromJson(Map<String, dynamic> json) {
    return CompletionImage(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class JobActions {
  const JobActions({required this.canCollectPayment});

  final bool canCollectPayment;

  factory JobActions.fromJson(Map<String, dynamic> json) {
    return JobActions(canCollectPayment: json['canCollectPayment'] == true);
  }
}

class CustomerInfo {
  const CustomerInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
  });

  final String id;
  final String name;
  final String phone;
  final double rating;

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return CustomerInfo(
      id: user['id']?.toString() ?? user['_id']?.toString() ?? '',
      name: user['name']?.toString() ?? user['fullName']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      rating: (user['rating'] ?? user['averageRating'] ?? 5.0).toDouble(),
    );
  }
}

class AddressInfo {
  const AddressInfo({
    required this.id,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.landmark,
    required this.fullAddress,
  });

  final String id;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String landmark;
  final String fullAddress;

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      line1: json['line1']?.toString() ?? json['address']?.toString() ?? '',
      line2: json['line2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? json['zipCode']?.toString() ?? '',
      latitude: (json['latitude'] ?? json['lat'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0)
          .toDouble(),
      landmark: json['landmark']?.toString() ?? '',
      fullAddress:
          json['fullAddress']?.toString() ??
          json['formatted']?.toString() ??
          '',
    );
  }
}

class GigBooking {
  const GigBooking({
    required this.id,
    required this.skill,
    required this.customerName,
    required this.customerRating,
    required this.addressLine,
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.etaMinutes,
    required this.slotLabel,
    required this.payout,
    required this.platformFee,
    required this.notes,
    required this.durationLabel,
    this.status = GigBookingStatus.pending,
    this.nextStep,
    this.completionOtpVerified = false,
    this.completionImages = const [],
    this.actions,
    this.customer,
    this.address,
    this.startedAt,
  });

  final String id;
  final Skill skill;
  final String customerName;
  final double customerRating;
  final String addressLine;
  final String landmark;
  final double latitude;
  final double longitude;

  /// Straight-line distance from the worker's current location, in km.
  final double distanceKm;
  final int etaMinutes;

  /// 'Today, 4:30 PM' or 'ASAP'.
  final String slotLabel;

  /// Worker's earning for this job, in rupees.
  final int payout;

  /// Platform's cut, in rupees. [totalPaid] = payout + platformFee.
  final int platformFee;

  /// Customer instructions for the job.
  final String notes;

  /// Human visit duration, e.g. '60 min'.
  final String durationLabel;
  final GigBookingStatus status;

  /// Next step for the vendor (from API response)
  final JobNextStep? nextStep;

  /// Whether the completion OTP has been verified
  final bool completionOtpVerified;

  /// Photos of completed work
  final List<CompletionImage> completionImages;

  /// Actions the vendor can take
  final JobActions? actions;

  /// Customer details (populated after accepting)
  final CustomerInfo? customer;

  /// Full address details (populated after accepting)
  final AddressInfo? address;

  /// Server timestamp for jobs that have already started.
  final DateTime? startedAt;

  /// What the customer paid in total (worker payout + platform fee).
  int get totalPaid => payout + platformFee;

  factory GigBooking.fromJson(Map<String, dynamic> json) {
    // Booking responses include a nested `job` object for workflow metadata
    // (`nextStep`, `completionOtpVerified`). It is not the booking itself.
    // Only use a nested object when the outer response has no booking id.
    final nestedJob = json['job'] as Map<String, dynamic>?;
    final booking = _readString(json, const ['id', '_id', 'bookingId']) != null
        ? json
        : nestedJob ?? json;
    final workflow = identical(booking, json) ? nestedJob : null;
    final customer = _readMap(booking, const ['customer', 'user', 'client']);
    final address = _readMap(booking, const ['address', 'location']);
    final service = _readMap(booking, const ['service', 'skill', 'category']);
    final coordinates = _readCoordinates(booking, address);
    final skillId =
        _readString(booking, const ['skillId', 'serviceId', 'categoryId']) ??
        _readString(service, const ['id', '_id', 'slug', 'categoryId']);
    final serviceName = _readString(service, const [
      'name',
      'title',
      'label',
      'categoryName',
    ]);
    // `service.id` is a UUID in the live vendor API, while the app catalogue
    // uses short ids (for example, `appliance`). Resolve the API service name
    // before falling back so an Appliance booking is never shown as Civil.
    final skill =
        skillByReference(skillId) ??
        skillByReference(serviceName) ??
        skillByReference(
          _readString(booking, const ['serviceName', 'categoryName']),
        ) ??
        skills.first;

    final rawNextStep = _readString(workflow ?? booking, const ['nextStep']);
    final nextStep = rawNextStep != null
        ? JobNextStep.fromString(rawNextStep)
        : null;

    return GigBooking(
      id: _readString(booking, const ['id', '_id', 'bookingId']) ?? '',
      skill: skill,
      customerName:
          _readString(booking, const ['customerName', 'clientName']) ??
          _readString(customer, const ['name', 'fullName']) ??
          'Customer',
      customerRating:
          _readDouble(customer, const ['rating', 'averageRating']) ??
          _readDouble(booking, const ['customerRating']) ??
          5.0,
      addressLine:
          _readString(booking, const ['addressLine', 'address']) ??
          _readString(address, const [
            'line',
            'line1',
            'fullAddress',
            'formatted',
          ]) ??
          '',
      landmark:
          _readString(booking, const ['landmark']) ??
          _readString(address, const ['landmark']) ??
          '',
      latitude: coordinates.$1,
      longitude: coordinates.$2,
      distanceKm: _readDouble(booking, const ['distanceKm', 'distance']) ?? 0,
      etaMinutes: _readInt(booking, const ['etaMinutes', 'eta']) ?? 0,
      slotLabel: _slotLabel(booking),
      payout:
          _readInt(booking, const [
            'payout',
            'vendorPayout',
            'earning',
            'price',
          ]) ??
          0,
      platformFee: _readInt(booking, const ['platformFee', 'commission']) ?? 0,
      notes:
          _readString(booking, const [
            'notes',
            'instructions',
            'description',
          ]) ??
          '',
      durationLabel:
          _readString(booking, const ['durationLabel', 'duration']) ?? '60 min',
      status: _parseStatus(
        _readString(booking, const ['status', 'bookingStatus']),
      ),
      nextStep: nextStep,
      completionOtpVerified:
          (workflow ?? booking)['completionOtpVerified'] == true,
      completionImages: (booking['completionImages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CompletionImage.fromJson)
          .toList(growable: false),
      actions: booking['actions'] != null
          ? JobActions.fromJson(booking['actions'] as Map<String, dynamic>)
          : null,
      customer: customer.isNotEmpty ? CustomerInfo.fromJson(customer) : null,
      address: address.isNotEmpty ? AddressInfo.fromJson(address) : null,
      startedAt: DateTime.tryParse(
        _readString(booking, const ['startedAt']) ?? '',
      )?.toLocal(),
    );
  }

  GigBooking copyWith({
    GigBookingStatus? status,
    JobNextStep? nextStep,
    bool? completionOtpVerified,
    List<CompletionImage>? completionImages,
    JobActions? actions,
    CustomerInfo? customer,
    AddressInfo? address,
    DateTime? startedAt,
  }) {
    return GigBooking(
      id: id,
      skill: skill,
      customerName: customerName,
      customerRating: customerRating,
      addressLine: addressLine,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      slotLabel: slotLabel,
      payout: payout,
      platformFee: platformFee,
      notes: notes,
      durationLabel: durationLabel,
      status: status ?? this.status,
      nextStep: nextStep ?? this.nextStep,
      completionOtpVerified:
          completionOtpVerified ?? this.completionOtpVerified,
      completionImages: completionImages ?? this.completionImages,
      actions: actions ?? this.actions,
      customer: customer ?? this.customer,
      address: address ?? this.address,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
  }
  return const <String, dynamic>{};
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
  }
  return null;
}

(double, double) _readCoordinates(
  Map<String, dynamic> json,
  Map<String, dynamic> address,
) {
  final latitude =
      _readDouble(json, const ['latitude', 'lat']) ??
      _readDouble(address, const ['latitude', 'lat']) ??
      0;
  final longitude =
      _readDouble(json, const ['longitude', 'lng', 'lon']) ??
      _readDouble(address, const ['longitude', 'lng', 'lon']) ??
      0;
  return (latitude, longitude);
}

String _slotLabel(Map<String, dynamic> json) {
  final explicit = _readString(json, const [
    'slotLabel',
    'slot',
    'scheduledFor',
    'scheduledAt',
  ]);
  if (explicit != null) {
    final date = DateTime.tryParse(explicit)?.toLocal();
    if (date == null) return explicit;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
  final windowStart = _readString(json, const ['windowStart', 'startTime']);
  final windowEnd = _readString(json, const ['windowEnd', 'endTime']);
  if (windowStart != null && windowEnd != null) {
    return '$windowStart - $windowEnd';
  }
  return 'ASAP';
}

GigBookingStatus _parseStatus(String? rawStatus) {
  final normalized = (rawStatus ?? '').toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  return switch (normalized) {
    'awaitingpayment' => GigBookingStatus.awaitingPayment,
    'pending' => GigBookingStatus.pending,
    'matching' => GigBookingStatus.matching,
    'accepted' || 'assigned' => GigBookingStatus.assigned,
    'inprogress' || 'ongoing' || 'started' => GigBookingStatus.inProgress,
    'completed' || 'done' => GigBookingStatus.completed,
    'declined' || 'rejected' => GigBookingStatus.cancelled,
    'cancelled' || 'canceled' => GigBookingStatus.cancelled,
    _ => GigBookingStatus.pending,
  };
}
