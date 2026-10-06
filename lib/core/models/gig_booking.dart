import 'skill.dart';

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
