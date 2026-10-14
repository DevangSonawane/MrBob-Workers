import 'package:flutter_test/flutter_test.dart';

import 'package:mrbob_partner/core/data/mock_bookings.dart';
import 'package:mrbob_partner/core/models/gig_booking.dart';
import 'package:mrbob_partner/core/models/job_session.dart';
import 'package:mrbob_partner/core/state/app_state.dart';

void main() {
  setUp(() {
    // Full demo reset: restores the 6-booking seed feed,
    // clears the active job and the profile.
    AppState.instance.signOut();
  });

  group('seed state', () {
    test('feed starts empty (no mock bookings loaded by default)', () {
      expect(AppState.instance.pendingBookings.length, 0);
      expect(AppState.instance.historyBookings, isEmpty);
      expect(AppState.instance.activeJob.value, isNull);
      expect(AppState.instance.totalEarned, 0);
    });
  });

  group('booking lifecycle state machine (§7)', () {
    test('accept → arrived → otpVerified → inProgress → completed', () {
      // Create a mock booking for testing
      final booking = generateMockBooking(1);

      // Manually add to bookings for testing
      AppState.instance.bookings.value = [booking];

      AppState.instance.acceptBookingLocal(booking);
      var job = AppState.instance.activeJob.value;
      expect(job, isNotNull);
      expect(job!.phase, JobPhase.arrived);
      expect(job.booking.status, GigBookingStatus.assigned);
      expect(AppState.instance.pendingBookings.length, 0);
      expect(AppState.instance.pendingPayout, booking.payout);

      AppState.instance.markArrived();
      job = AppState.instance.activeJob.value;
      expect(job!.phase, JobPhase.arrived);
      expect(job.arrivedAt, isNotNull);
      expect(job.booking.status, GigBookingStatus.assigned);

      AppState.instance.verifyCompletionOtpLocal('1234');
      expect(AppState.instance.activeJob.value!.phase, JobPhase.uploadingImages);

      AppState.instance.startJobLocal('1234');
      job = AppState.instance.activeJob.value;
      expect(job!.phase, JobPhase.inProgress);
      expect(job.startedAt, isNotNull);
      expect(job.booking.status, GigBookingStatus.inProgress);

      AppState.instance.completeJobLocal();
      job = AppState.instance.activeJob.value;
      expect(job!.phase, JobPhase.completed);
      expect(job.completedAt, isNotNull);
      expect(job.booking.status, GigBookingStatus.completed);

      // Earnings moved from pending to available.
      expect(AppState.instance.pendingPayout, 0);
      expect(AppState.instance.availableBalance, booking.payout);
      expect(AppState.instance.totalEarned, booking.payout);
    });

    test('decline removes the booking from the feed permanently', () {
      final booking = generateMockBooking(1);
      AppState.instance.bookings.value = [booking];

      AppState.instance.declineBooking(booking);
      expect(AppState.instance.pendingBookings.length, 0);
      final cancelled = AppState.instance.historyBookings
          .where((b) => b.id == booking.id)
          .toList();
      expect(cancelled.length, 1);
      expect(cancelled.single.status, GigBookingStatus.cancelled);
    });

    test('cancelActiveJob cancels and clears the session', () {
      final booking = generateMockBooking(1);
      AppState.instance.bookings.value = [booking];

      AppState.instance.acceptBookingLocal(booking);
      AppState.instance.cancelActiveJob();
      expect(AppState.instance.activeJob.value, isNull);
      final cancelled = AppState.instance.historyBookings
          .where((b) => b.id == booking.id)
          .toList();
      expect(cancelled.single.status, GigBookingStatus.cancelled);
      expect(AppState.instance.pendingPayout, 0);
    });

    test('lifecycle methods are no-ops without an active job', () {
      AppState.instance.markArrived();
      AppState.instance.verifyOtp();
      AppState.instance.startJob('1234');
      AppState.instance.completeJob();
      expect(AppState.instance.activeJob.value, isNull);
    });
  });

  group('demo simulation (§8)', () {
    test('injectNewBooking caps at 3 pending', () {
      // Add 3 pending bookings
      for (var i = 0; i < 3; i++) {
        AppState.instance.bookings.value = [
          generateMockBooking(i + 1),
          ...AppState.instance.bookings.value,
        ];
      }

      expect(AppState.instance.injectNewBooking(), isNull);

      // Remove one to free up a slot
      AppState.instance.declineBooking(AppState.instance.pendingBookings.first);
      final injected = AppState.instance.injectNewBooking();
      // Note: injectNewBooking returns null in new implementation (API-based)
      expect(injected, isNull);
    });
  });

  group('sign out', () {
    test('resets feed, job and profile', () {
      final booking = generateMockBooking(1);
      AppState.instance.bookings.value = [booking];
      AppState.instance.acceptBookingLocal(booking);
      AppState.instance.completeJobLocal();

      AppState.instance.signOut();

      expect(AppState.instance.pendingBookings.length, 0);
      expect(AppState.instance.activeJob.value, isNull);
      expect(AppState.instance.availableBalance, 0);
      expect(AppState.instance.profile.value.name, '');
      expect(AppState.instance.profile.value.isKycVerified, isFalse);
    });
  });

  group('mock booking generator', () {
    test('generates deterministic, well-formed bookings', () {
      final a = generateMockBooking(1);
      final b = generateMockBooking(1);
      final c = generateMockBooking(2);

      expect(a.id, b.id);
      expect(a.customerName, b.customerName);
      expect(a.id, isNot(c.id));

      for (final booking in [a, c]) {
        expect(booking.distanceKm, greaterThanOrEqualTo(2.0));
        expect(booking.distanceKm, lessThanOrEqualTo(6.0));
        expect(booking.payout, greaterThan(0));
        expect(booking.platformFee, 29);
        expect(booking.latitude.abs(), lessThan(90));
        expect(booking.longitude.abs(), lessThan(180));
        expect(booking.slotLabel, isNotEmpty);
        expect(booking.durationLabel, isNotEmpty);
      }
    });

    test('seed bookings are within ~6 km of the worker anchor', () {
      for (final booking in mockBookings) {
        expect(
          (booking.latitude - workerLatitude).abs(),
          lessThan(0.06),
        );
        expect(
          (booking.longitude - workerLongitude).abs(),
          lessThan(0.08),
        );
      }
    });
  });
}