import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/gig_booking.dart'
    show GigBooking, GigBookingStatus, CompletionImage, JobNextStep;
import '../models/gig_worker_profile.dart';
import '../models/job_session.dart';
import '../../features/vendor/data/vendor_repository.dart';

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
      ValueNotifier<List<GigBooking>>(<GigBooking>[]);

  final ValueNotifier<JobSession?> activeJob = ValueNotifier<JobSession?>(null);

  /// Worker availability — drives the Home online toggle.
  /// When offline, the feed shows a paused state and no new
  /// bookings are injected.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  /// Whether we're currently loading data
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Error message for UI display
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// Bookings still swipable in the feed (PENDING, MATCHING, AWAITING_PAYMENT).
  List<GigBooking> get pendingBookings => bookings.value
      .where((booking) =>
          booking.status == GigBookingStatus.pending ||
          booking.status == GigBookingStatus.matching ||
          booking.status == GigBookingStatus.awaitingPayment)
      .toList();

  /// Everything else: active, completed, declined, cancelled.
  List<GigBooking> get historyBookings => bookings.value
      .where((booking) =>
          booking.status != GigBookingStatus.pending &&
          booking.status != GigBookingStatus.matching &&
          booking.status != GigBookingStatus.awaitingPayment)
      .toList();

  /// Earnings of jobs currently being worked (not yet paid out).
  int get pendingPayout => bookings.value
      .where((booking) =>
          booking.status == GigBookingStatus.assigned ||
          booking.status == GigBookingStatus.inProgress)
      .fold(0, (sum, booking) => sum + booking.payout);

  /// Earnings of completed jobs — moved here on completion.
  int get availableBalance => bookings.value
      .where((booking) => booking.status == GigBookingStatus.completed)
      .fold(0, (sum, booking) => sum + booking.payout);

  int get totalEarned => availableBalance + pendingPayout;

  bool get hasActiveJob => activeJob.value != null;

  VendorRepository? _repo;

  void _setRepo(VendorRepository repo) {
    _repo = repo;
  }

  // ------------------------------------------------------------------
  // Profile
  // ------------------------------------------------------------------

  void updateProfile(GigWorkerProfile updated) {
    profile.value = updated;
  }

  Future<void> loadProfile() async {
    if (_repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final p = await _repo!.getProfile();
      profile.value = p;
    } catch (e) {
      errorMessage.value = 'Failed to load profile: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------------------------------------------------------
  // Booking lifecycle (§7 state machine) - using real API calls
  // ------------------------------------------------------------------

  Future<void> loadAvailableJobs({int page = 1, int limit = 20}) async {
    if (_repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final jobs = await _repo!.getAvailableJobs(page: page, limit: limit);
      // Replace only pending bookings, keep history
      final current = bookings.value;
      final history = current.where((b) =>
          b.status != GigBookingStatus.pending &&
          b.status != GigBookingStatus.matching &&
          b.status != GigBookingStatus.awaitingPayment).toList();
      bookings.value = [...jobs, ...history];
    } catch (e) {
      errorMessage.value = 'Failed to load jobs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyJobs({
    String? status,
    String? scope,
    int page = 1,
    int limit = 20,
  }) async {
    if (_repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final jobs = await _repo!.getMyJobs(
        status: status,
        scope: scope,
        page: page,
        limit: limit,
      );
      bookings.value = jobs;
    } catch (e) {
      errorMessage.value = 'Failed to load jobs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptBooking(GigBooking booking) async {
    if (_repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final accepted = await _repo!.acceptJob(booking.id);
      _replaceBooking(accepted);
      activeJob.value = JobSession(booking: accepted, phase: JobPhase.arrived, arrivedAt: DateTime.now());
    } catch (e) {
      errorMessage.value = 'Failed to accept job: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void declineBooking(GigBooking booking) {
    _replaceBooking(booking.copyWith(status: GigBookingStatus.cancelled));
  }

  Future<void> markArrived() async {
    final job = activeJob.value;
    if (job == null) return;
    // Arrived is a local state; the API doesn't have a separate "arrived" endpoint
    // The job is already ASSIGNED after accept. We just update local phase.
    activeJob.value = job.copyWith(
      phase: JobPhase.arrived,
      arrivedAt: DateTime.now(),
    );
  }

  Future<void> startJob(String otp) async {
    final job = activeJob.value;
    if (job == null || _repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final started = await _repo!.startJob(job.booking.id, otp);
      _replaceBooking(started);
      activeJob.value = job.copyWith(
        booking: started,
        phase: JobPhase.inProgress,
        startedAt: DateTime.now(),
      );
    } catch (e) {
      errorMessage.value = 'Failed to start job: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyCompletionOtp(String otp) async {
    final job = activeJob.value;
    if (job == null || _repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final verified = await _repo!.verifyCompletionOtp(job.booking.id, otp);
      _replaceBooking(verified);
      activeJob.value = job.copyWith(
        booking: verified,
        phase: JobPhase.uploadingImages,
      );
    } catch (e) {
      errorMessage.value = 'Failed to verify OTP: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadCompletionImages(List<MultipartFile> images) async {
    final job = activeJob.value;
    if (job == null || _repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final updated = await _repo!.uploadCompletionImages(job.booking.id, images);
      _replaceBooking(updated);
      activeJob.value = job.copyWith(
        booking: updated,
        uploadedImages: updated.completionImages,
        phase: JobPhase.inProgress, // Can continue working or complete
      );
    } catch (e) {
      errorMessage.value = 'Failed to upload images: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeJob() async {
    final job = activeJob.value;
    if (job == null || _repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final completed = await _repo!.completeJob(job.booking.id);
      _replaceBooking(completed);
      activeJob.value = job.copyWith(
        booking: completed,
        phase: JobPhase.completed,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      errorMessage.value = 'Failed to complete job: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Demo escape hatch: abandon the active job (cancels it).
  Future<void> cancelActiveJob() async {
    final job = activeJob.value;
    if (job == null) return;
    // API doesn't have cancel endpoint for vendor, just update local state
    _replaceBooking(
      job.booking.copyWith(status: GigBookingStatus.cancelled),
    );
    activeJob.value = null;
  }

  /// Called when leaving the completion screen: the finished job
  /// stays in history/earnings, but it is no longer active, so Home
  /// and Jobs stop offering a "view details" continuation for it.
  void clearFinishedJob() {
    activeJob.value = null;
  }

  // ------------------------------------------------------------------
  // Demo simulation (§8)
  // ------------------------------------------------------------------

  /// Inject a fresh booking into the feed for demo purposes.
  /// Caps at 3 pending.
  /// Returns the new booking, or null when the cap is hit.
  GigBooking? injectNewBooking() {
    if (!isOnline.value) return null;
    if (pendingBookings.length >= 3) return null;
    // This is a demo method - in production, bookings come from the API
    return null;
  }

  // Backward compatibility methods for tests
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

  // Local test helpers (don't call API)
  void acceptBookingLocal(GigBooking booking) {
    final accepted = booking.copyWith(status: GigBookingStatus.assigned);
    _replaceBooking(accepted);
    activeJob.value = JobSession(booking: accepted, phase: JobPhase.arrived, arrivedAt: DateTime.now());
  }

  void startJobLocal(String otp) {
    final job = activeJob.value;
    if (job == null) return;
    final started = job.booking.copyWith(status: GigBookingStatus.inProgress);
    _replaceBooking(started);
    activeJob.value = job.copyWith(
      booking: started,
      phase: JobPhase.inProgress,
      startedAt: DateTime.now(),
    );
  }

  void verifyCompletionOtpLocal(String otp) {
    final job = activeJob.value;
    if (job == null) return;
    final verified = job.booking.copyWith(completionOtpVerified: true);
    _replaceBooking(verified);
    activeJob.value = job.copyWith(
      booking: verified,
      phase: JobPhase.uploadingImages,
    );
  }

  void completeJobLocal() {
    final job = activeJob.value;
    if (job == null) return;
    final completed = job.booking.copyWith(status: GigBookingStatus.completed);
    _replaceBooking(completed);
    activeJob.value = job.copyWith(
      booking: completed,
      phase: JobPhase.completed,
      completedAt: DateTime.now(),
    );
  }

  // ------------------------------------------------------------------
  // Initialization
  // ------------------------------------------------------------------

  Future<void> initialize(VendorRepository repo) async {
    _setRepo(repo);
    await Future.wait([
      loadProfile(),
      loadMyJobs(scope: 'upcoming'),
      loadAvailableJobs(),
    ]);
  }

  // ------------------------------------------------------------------
  // Sign out (demo: full reset back to login)
  // ------------------------------------------------------------------

  void signOut() {
    bookings.value = <GigBooking>[];
    activeJob.value = null;
    profile.value = const GigWorkerProfile();
    errorMessage.value = null;
  }

  void _replaceBooking(GigBooking updated) {
    final list = List<GigBooking>.of(bookings.value);
    final index = list.indexWhere((b) => b.id == updated.id);
    if (index >= 0) {
      list[index] = updated;
    } else {
      list.insert(0, updated);
    }
    bookings.value = list;
  }
}