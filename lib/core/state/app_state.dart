import 'package:flutter/foundation.dart';

import '../data/mock_bookings.dart';
import '../models/gig_booking.dart';
import '../models/gig_worker_profile.dart';
import '../models/job_session.dart';

/// Zero-package app state (client-app convention: plain
/// `setState` locally, this singleton for cross-tab state).
///
/// Owns the worker profile, the booking feed, the active job
/// session and derives earnings from booking statuses:
/// pending payout = accepted/arrived/in-progress payouts,
/// available balance = completed payouts.
class AppState {
  AppState._();
  static final AppState instance = AppState._();

  final ValueNotifier<GigWorkerProfile> profile = ValueNotifier<GigWorkerProfile>(
    const GigWorkerProfile(),
  );

  final ValueNotifier<List<GigBooking>> bookings =
      ValueNotifier<List<GigBooking>>(List<GigBooking>.of(mockBookings));

  final ValueNotifier<JobSession?> activeJob = ValueNotifier<JobSession?>(null);

  /// Bookings still swipable in the feed.
  List<GigBooking> get pendingBookings => bookings.value
      .where((booking) => booking.status == GigBookingStatus.incoming)
      .toList();

  /// Everything else: active, completed, declined, cancelled.
  List<GigBooking> get historyBookings => bookings.value
      .where((booking) => booking.status != GigBookingStatus.incoming)
      .toList();

  /// Earnings of jobs currently being worked (not yet paid out).
  int get pendingPayout => bookings.value
      .where((booking) =>
          booking.status == GigBookingStatus.accepted ||
          booking.status == GigBookingStatus.arrived ||
          booking.status == GigBookingStatus.inProgress)
      .fold(0, (sum, booking) => sum + booking.payout);

  /// Earnings of completed jobs — moved here on completion.
  int get availableBalance => bookings.value
      .where((booking) => booking.status == GigBookingStatus.completed)
      .fold(0, (sum, booking) => sum + booking.payout);

  int get totalEarned => availableBalance + pendingPayout;

  bool get hasActiveJob => activeJob.value != null;

  // ------------------------------------------------------------------
  // Profile
  // ------------------------------------------------------------------

  void updateProfile(GigWorkerProfile updated) {
    profile.value = updated;
  }

  // ------------------------------------------------------------------
  // Booking lifecycle (§7 state machine)
  // ------------------------------------------------------------------

  void acceptBooking(GigBooking booking) {
    final updated = booking.copyWith(status: GigBookingStatus.accepted);
    _replaceBooking(updated);
    activeJob.value = JobSession(booking: updated);
  }

  void declineBooking(GigBooking booking) {
    _replaceBooking(booking.copyWith(status: GigBookingStatus.declined));
  }

  void markArrived() {
    final job = activeJob.value;
    if (job == null) return;
    final updated = job.booking.copyWith(status: GigBookingStatus.arrived);
    _replaceBooking(updated);
    activeJob.value = job.copyWith(
      booking: updated,
      phase: JobPhase.arrived,
      arrivedAt: DateTime.now(),
    );
  }

  void verifyOtp() {
    final job = activeJob.value;
    if (job == null) return;
    activeJob.value = job.copyWith(phase: JobPhase.otpVerified);
  }

  void startWorking() {
    final job = activeJob.value;
    if (job == null) return;
    final updated = job.booking.copyWith(status: GigBookingStatus.inProgress);
    _replaceBooking(updated);
    activeJob.value = job.copyWith(
      booking: updated,
      phase: JobPhase.inProgress,
      startedAt: DateTime.now(),
    );
  }

  void completeJob() {
    final job = activeJob.value;
    if (job == null) return;
    final updated = job.booking.copyWith(status: GigBookingStatus.completed);
    _replaceBooking(updated);
    activeJob.value = job.copyWith(
      booking: updated,
      phase: JobPhase.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Demo escape hatch: abandon the active job (cancels it).
  void cancelActiveJob() {
    final job = activeJob.value;
    if (job == null) return;
    _replaceBooking(
      job.booking.copyWith(status: GigBookingStatus.cancelled),
    );
    activeJob.value = null;
  }

  // ------------------------------------------------------------------
  // Demo simulation (§8)
  // ------------------------------------------------------------------

  /// Inject a fresh booking into the feed. Caps at 3 pending.
  /// Returns the new booking, or null when the cap is hit.
  GigBooking? injectNewBooking() {
    if (pendingBookings.length >= 3) return null;
    final booking = generateMockBooking(
      bookings.value.length + 100 + DateTime.now().millisecondsSinceEpoch % 997,
    );
    bookings.value = <GigBooking>[booking, ...bookings.value];
    return booking;
  }

  // ------------------------------------------------------------------
  // Sign out (demo: full reset back to login)
  // ------------------------------------------------------------------

  void signOut() {
    bookings.value = List<GigBooking>.of(mockBookings);
    activeJob.value = null;
    profile.value = const GigWorkerProfile();
  }

  void _replaceBooking(GigBooking updated) {
    final list = List<GigBooking>.of(bookings.value);
    final index = list.indexWhere((b) => b.id == updated.id);
    if (index >= 0) list[index] = updated;
    bookings.value = list;
  }
}
