import 'skill.dart';
import '../data/skills_data.dart';

enum GigBookingStatus {
  incoming('Incoming'),
  accepted('Accepted'),
  arrived('Arrived'),
  inProgress('In progress'),
  completed('Completed'),
  declined('Declined'),
  cancelled('Cancelled');

  const GigBookingStatus(this.label);

  final String label;

  bool get isActive =>
      this == GigBookingStatus.accepted ||
      this == GigBookingStatus.arrived ||
      this == GigBookingStatus.inProgress;
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
    this.status = GigBookingStatus.incoming,
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

  /// What the customer paid in total (worker payout + platform fee).
  int get totalPaid => payout + platformFee;

  factory GigBooking.fromJson(Map<String, dynamic> json) {
    final customer = _readMap(json, const ['customer', 'user', 'client']);
    final address = _readMap(json, const ['address', 'location']);
    final service = _readMap(json, const ['service', 'skill', 'category']);
    final coordinates = _readCoordinates(json, address);
    final skillId =
        _readString(json, const ['skillId', 'serviceId', 'categoryId']) ??
        _readString(service, const ['id', '_id', 'slug']);

    return GigBooking(
      id: _readString(json, const ['id', '_id', 'bookingId']) ?? '',
      skill: skillById(skillId ?? ''),
      customerName:
          _readString(json, const ['customerName', 'clientName']) ??
          _readString(customer, const ['name', 'fullName']) ??
          'Customer',
      customerRating:
          _readDouble(customer, const ['rating', 'averageRating']) ??
          _readDouble(json, const ['customerRating']) ??
          5.0,
      addressLine:
          _readString(json, const ['addressLine', 'address']) ??
          _readString(address, const ['line1', 'fullAddress', 'formatted']) ??
          '',
      landmark:
          _readString(json, const ['landmark']) ??
          _readString(address, const ['landmark']) ??
          '',
      latitude: coordinates.$1,
      longitude: coordinates.$2,
      distanceKm: _readDouble(json, const ['distanceKm', 'distance']) ?? 0,
      etaMinutes: _readInt(json, const ['etaMinutes', 'eta']) ?? 0,
      slotLabel: _slotLabel(json),
      payout: _readInt(json, const ['payout', 'vendorPayout', 'earning']) ?? 0,
      platformFee: _readInt(json, const ['platformFee', 'commission']) ?? 0,
      notes: _readString(json, const ['notes', 'instructions']) ?? '',
      durationLabel:
          _readString(json, const ['durationLabel', 'duration']) ?? '60 min',
      status: _parseStatus(
        _readString(json, const ['status', 'bookingStatus']),
      ),
    );
  }

  GigBooking copyWith({GigBookingStatus? status}) {
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
  ]);
  if (explicit != null) return explicit;
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
    'accepted' || 'assigned' => GigBookingStatus.accepted,
    'arrived' => GigBookingStatus.arrived,
    'inprogress' || 'ongoing' || 'started' => GigBookingStatus.inProgress,
    'completed' || 'done' => GigBookingStatus.completed,
    'declined' || 'rejected' => GigBookingStatus.declined,
    'cancelled' || 'canceled' => GigBookingStatus.cancelled,
    _ => GigBookingStatus.incoming,
  };
}
