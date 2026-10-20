import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../models/gig_booking.dart' show GigBooking, GigBookingStatus;
import '../models/gig_worker_profile.dart';
import '../models/job_session.dart';
import '../models/vendor_presence.dart';
import '../services/location_service.dart';
import '../../features/vendor/data/vendor_repository.dart';

/// Zero-package app state (client-app convention: plain
/// `setState` locally, this singleton for cross-tab state).
///
/// Owns the worker profile, the booking feed, the active job
/// session and derives earnings from booking statuses:
/// pending payout = accepted/arrived/in-progress payouts,
/// available balance = completed payouts.
class AppState with WidgetsBindingObserver {
  AppState._();
  static final AppState instance = AppState._();

  final ValueNotifier<GigWorkerProfile> profile =
      ValueNotifier<GigWorkerProfile>(const GigWorkerProfile());

  final ValueNotifier<List<GigBooking>> bookings =
      ValueNotifier<List<GigBooking>>(<GigBooking>[]);

  final ValueNotifier<JobSession?> activeJob = ValueNotifier<JobSession?>(null);

  /// Worker availability — drives the Home online toggle.
  /// When offline, the feed shows a paused state and no new
  /// bookings are injected. Kept in sync with [presence].
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);

  /// H3 presence: the server's view of the vendor — online state, last
  /// position, the H3 cell and the heartbeat interval. The online switch
  /// on Home is bound to [presence].
  final ValueNotifier<VendorPresence> presence =
      ValueNotifier<VendorPresence>(const VendorPresence());

  /// Whether we're currently loading data
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Error message for UI display
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// Bookings still swipable in the feed (PENDING, MATCHING, AWAITING_PAYMENT).
  List<GigBooking> get pendingBookings => bookings.value
      .where(
        (booking) =>
            booking.status == GigBookingStatus.pending ||
            booking.status == GigBookingStatus.matching ||
            booking.status == GigBookingStatus.awaitingPayment,
      )
      .toList();

  /// Everything else: active, completed, declined, cancelled.
  List<GigBooking> get historyBookings => bookings.value
      .where(
        (booking) =>
            booking.status != GigBookingStatus.pending &&
            booking.status != GigBookingStatus.matching &&
            booking.status != GigBookingStatus.awaitingPayment,
      )
      .toList();

  /// Earnings of jobs currently being worked (not yet paid out).
  int get pendingPayout => bookings.value
      .where(
        (booking) =>
            booking.status == GigBookingStatus.assigned ||
            booking.status == GigBookingStatus.inProgress,
      )
      .fold(0, (sum, booking) => sum + booking.payout);

  /// Earnings of completed jobs — moved here on completion.
  int get availableBalance => bookings.value
      .where((booking) => booking.status == GigBookingStatus.completed)
      .fold(0, (sum, booking) => sum + booking.payout);

  int get totalEarned => availableBalance + pendingPayout;

  bool get hasActiveJob => activeJob.value != null;

  VendorRepository? _repo;
  final LocationService _location = const LocationService();
  Timer? _presenceTimer;

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
  // Presence (H3) — online switch, position heartbeat
  // ------------------------------------------------------------------

  /// Reads the server presence so the online switch starts in the right
  /// state after an app restart.
  Future<void> loadPresence() async {
    if (_repo == null) return;
    try {
      final loaded = await _repo!.getPresence();
      _applyPresence(loaded);
      if (loaded.online) {
        _startPresenceTimer();
        // Push a position right away — the server may have expired the
        // position while the app was closed.
        unawaited(refreshPosition());
      }
    } catch (_) {
      // Keep the local state — the switch can still be flipped by hand.
    }
  }

  /// Flips the online switch. Returns true when the server accepted it.
  ///
  /// Going online needs a position: the server answers `400 Send your
  /// location` when a vendor goes online without one.
  Future<bool> setOnline(bool online) async {
    if (_repo == null) return false;
    try {
      errorMessage.value = null;
      if (!online) {
        final updated = await _repo!.updatePresence(online: false);
        _applyPresence(updated.copyWith(online: false));
        _stopPresenceTimer();
        return true;
      }

      final position = await _location.currentPosition();
      if (position == null) {
        errorMessage.value =
            'Allow location access to receive nearby job requests.';
        return false;
      }

      final updated = await _repo!.updatePresence(
        online: true,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _applyPresence(updated);
      _startPresenceTimer();
      return true;
    } on LocationRequiredException catch (_) {
      errorMessage.value =
          'Turn on location access to receive nearby job requests.';
      return false;
    } catch (e) {
      errorMessage.value = 'Could not update your status: $e';
      return false;
    }
  }

  /// Pushes the current position to the server. The server stops sending
  /// offers after 5 minutes without a position, so this runs on a timer
  /// and again whenever the app comes back to the foreground.
  Future<void> refreshPosition() async {
    if (_repo == null || !presence.value.online) return;
    final position = await _location.currentPosition();
    if (position == null) return;
    try {
      final updated = await _repo!.updatePresence(
        online: true,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _applyPresence(updated);
      if (!updated.online) _stopPresenceTimer();
    } catch (_) {
      // A dropped heartbeat is not fatal — the next tick retries.
    }
  }

  /// Goes offline before the session ends so the server stops routing
  /// offers to this vendor.
  Future<void> goOfflineOnSignOut() async {
    _stopPresenceTimer();
    if (_repo == null) return;
    try {
      final updated = await _repo!.updatePresence(online: false);
      _applyPresence(updated.copyWith(online: false));
    } catch (_) {
      // The session is ending anyway — the server expires it on its own.
    }
  }

  void _applyPresence(VendorPresence value) {
    presence.value = value;
    isOnline.value = value.online;
  }

  void _startPresenceTimer() {
    _stopPresenceTimer();
    final seconds = presence.value.updateEverySeconds;
    _presenceTimer = Timer.periodic(
      Duration(seconds: seconds > 0 ? seconds : 30),
      (_) => refreshPosition(),
    );
  }

  void _stopPresenceTimer() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The heartbeat may have been throttled in the background, so push the
    // position as soon as the app is back in the foreground.
    if (state == AppLifecycleState.resumed && presence.value.online) {
      unawaited(refreshPosition());
    }
  }

  // ------------------------------------------------------------------
  // Booking lifecycle (§7 state machine) - using real API calls
  // ------------------------------------------------------------------

  /// Loads the open jobs. [silent] keeps the loading spinner and the
  /// error banner out of the way — used by the 5 second poll.
  Future<void> loadAvailableJobs({
    int page = 1,
    int limit = 20,
    bool silent = false,
  }) async {
    if (_repo == null) return;
    try {
      if (!silent) {
        isLoading.value = true;
        errorMessage.value = null;
      }
      final jobs = await _repo!.getAvailableJobs(page: page, limit: limit);
      final matchingJobs = _filterByVendorServices(jobs);
      // Replace only pending bookings, keep history
      final current = bookings.value;
      final history = current
          .where(
            (b) =>
                b.status != GigBookingStatus.pending &&
                b.status != GigBookingStatus.matching &&
                b.status != GigBookingStatus.awaitingPayment,
          )
          .toList();
      bookings.value = [...matchingJobs, ...history];
    } catch (e) {
      if (!silent) errorMessage.value = 'Failed to load jobs: $e';
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// The 5 second poll that keeps offers flowing in while the vendor is
  /// online and looking at the jobs list.
  Future<void> pollAvailableJobs() {
    if (!presence.value.online) return Future<void>.value();
    return loadAvailableJobs(silent: true);
  }

  /// Keeps the feed scoped to the services the vendor declared, but never
  /// drops a job the server explicitly offered to this vendor — H3 already
  /// matched those by service and area.
  List<GigBooking> _filterByVendorServices(List<GigBooking> jobs) {
    final vendorSkillIds = profile.value.skills.map((skill) => skill.id).toSet();
    if (vendorSkillIds.isEmpty) return jobs;
    return jobs
        .where(
          (job) =>
              job.offer != null || vendorSkillIds.contains(job.skill.id),
        )
        .toList();
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
      if (scope != 'past') {
        _restoreActiveJob(jobs);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load jobs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Reloads the profile, assigned jobs and open jobs in the order required
  /// for service filtering. Used by pull-to-refresh on job-based tabs.
  Future<void> refreshBookings() async {
    await loadProfile();
    await loadMyJobs();
    await loadAvailableJobs();
  }

  Future<void> acceptBooking(GigBooking booking) async {
    if (_repo == null) return;
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final accepted = await _repo!.acceptJob(booking.id);
      _replaceBooking(accepted);
      activeJob.value = JobSession(
        booking: accepted,
        phase: JobPhase.arrived,
        arrivedAt: DateTime.now(),
      );
    } on JobUnavailableException catch (error) {
      // The offer ran out or another vendor was faster. Drop the job and
      // refresh the list so the feed matches the server again.
      removeBooking(booking.id);
      errorMessage.value = error.message;
      await loadAvailableJobs(silent: true);
      rethrow;
    } catch (e) {
      errorMessage.value = 'Failed to accept job: $e';
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Hands an offered job back so the next dispatch wave can pick it up.
  Future<void> declineBooking(GigBooking booking) async {
    // The job leaves the feed straight away — the offer is gone either way.
    _replaceBooking(booking.copyWith(status: GigBookingStatus.cancelled));
    if (_repo == null) return;
    try {
      await _repo!.declineJob(booking.id);
    } on JobUnavailableException {
      // The offer had already run out.
    } catch (e) {
      errorMessage.value = 'Failed to decline job: $e';
    }
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
      final updated = await _repo!.uploadCompletionImages(
        job.booking.id,
        images,
      );
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

  Future<GigBooking> rateCustomer({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    if (_repo == null) {
      throw StateError('Vendor repository is not initialized.');
    }
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final updated = await _repo!.rateCustomer(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      _replaceBooking(updated);
      final active = activeJob.value;
      if (active != null && active.booking.id == bookingId) {
        activeJob.value = active.copyWith(booking: updated);
      }
      return updated;
    } catch (e) {
      errorMessage.value = 'Failed to rate customer: $e';
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
    _replaceBooking(job.booking.copyWith(status: GigBookingStatus.cancelled));
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
    activeJob.value = JobSession(
      booking: accepted,
      phase: JobPhase.arrived,
      arrivedAt: DateTime.now(),
    );
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
    try {
      WidgetsBinding.instance.addObserver(this);
    } on StateError catch (_) {
      // Binding not initialized (e.g. in tests) — skip observer registration.
    }
    // Available jobs are filtered by profile skills and merged with current
    // assignments, so this must not race with either request.
    await loadProfile();
    await loadPresence();
    await loadMyJobs(scope: 'upcoming');
    await loadAvailableJobs();
  }

  // ------------------------------------------------------------------
  // Sign out (demo: full reset back to login)
  // ------------------------------------------------------------------

  void signOut() {
    _stopPresenceTimer();
    bookings.value = <GigBooking>[];
    activeJob.value = null;
    profile.value = const GigWorkerProfile();
    errorMessage.value = null;
    presence.value = const VendorPresence();
    isOnline.value = false;
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

  /// Drops a booking from the feed — used when an offer expired or another
  /// vendor took the job.
  void removeBooking(String id) {
    final list = bookings.value.where((b) => b.id != id).toList();
    bookings.value = list;
  }

  /// [activeJob] is in-memory only, so reconstruct it from the server after
  /// an app restart. Prefer an in-progress booking because it is further along
  /// than an assigned one and is the only job that can be continued.
  void _restoreActiveJob(List<GigBooking> jobs) {
    GigBooking? active;
    for (final booking in jobs) {
      if (booking.status == GigBookingStatus.inProgress) {
        active = booking;
        break;
      }
      if (active == null && booking.status == GigBookingStatus.assigned) {
        active = booking;
      }
    }

    if (active == null) {
      activeJob.value = null;
      return;
    }

    final isInProgress = active.status == GigBookingStatus.inProgress;
    activeJob.value = JobSession(
      booking: active,
      phase: isInProgress ? JobPhase.inProgress : JobPhase.arrived,
      arrivedAt: isInProgress ? null : DateTime.now(),
      startedAt: isInProgress ? (active.startedAt ?? DateTime.now()) : null,
      uploadedImages: active.completionImages,
    );
  }
}
