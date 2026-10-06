import 'gig_booking.dart';

enum JobPhase { enroute, arrived, otpPending, otpVerified, inProgress, completed }

/// The live job state machine. Immutable: every phase transition
/// produces a new session (the [activeJob] ValueNotifier fires on
/// the new instance), which keeps booking status flips visible to
/// listeners without dropping the phase timestamps.
class JobSession {
  const JobSession({
    required this.booking,
    this.phase = JobPhase.enroute,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
  });

  final GigBooking booking;
  final JobPhase phase;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Work time: [startedAt] → [completedAt] (or now while running).
  /// Computed from wall-clock diffs so it survives app pauses.
  Duration get elapsed {
    final start = startedAt;
    if (start == null) return Duration.zero;
    return (completedAt ?? DateTime.now()).difference(start);
  }

  JobSession copyWith({
    GigBooking? booking,
    JobPhase? phase,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return JobSession(
      booking: booking ?? this.booking,
      phase: phase ?? this.phase,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
