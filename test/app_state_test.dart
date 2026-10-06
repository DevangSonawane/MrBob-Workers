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
    test('feed starts with 6 pending bookings', () {
      expect(AppState.instance.pendingBookings.length, 6);
      expect(AppState.instance.historyBookings, isEmpty);
      expect(AppState.instance.activeJob.value, isNull);
      expect(AppState.instance.totalEarned, 0);
    });
  });

  group('booking lifecycle state machine (§7)', () {
    test('accept → arrived → otpVerified → inProgress → completed', () {
      final booking = AppState.instance.pendingBookings.first;

      AppState.instance.acceptBooking(booking);
      var job = AppState.instance.activeJob.value;
      expect(job, isNotNull);
      expect(job!.phase, JobPhase.enroute);
      expect(job.booking.status, GigBookingStatus.accepted);
      expect(AppState.instance.pendingBookings.length, 5);
      expect(AppState.instance.pendingPayout, booking.payout);

      AppState.instance.markArrived();
      job = AppState.instance.activeJob.value;
      expect(job!.phase, JobPhase.arrived);
      expect(job.arrivedAt, isNotNull);
      expect(job.booking.status, GigBookingStatus.arrived);

      AppState.instance.verifyOtp();
      expect(AppState.instance.activeJob.value!.phase, JobPhase.otpVerified);

      AppState.instance.startWorking();
      job = AppState.instance.activeJob.value;
      expect(job!.phase, JobPhase.inProgress);
      expect(job.startedAt, isNotNull);
      expect(job.booking.status, GigBookingStatus.inProgress);

      AppState.instance.completeJob();
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
      final booking = AppState.instance.pendingBookings.first;
      AppState.instance.declineBooking(booking);
      expect(AppState.instance.pendingBookings.length, 5);
      final declined = AppState.instance.historyBookings
          .where((b) => b.id == booking.id)
          .toList();
      expect(declined.length, 1);
      expect(declined.single.status, GigBookingStatus.declined);
    });

    test('cancelActiveJob cancels and clears the session', () {
      final booking = AppState.instance.pendingBookings.first;
      AppState.instance.acceptBooking(booking);
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
      AppState.instance.startWorking();
      AppState.instance.completeJob();
      expect(AppState.instance.activeJob.value, isNull);
    });
  });

  group('demo simulation (§8)', () {
    test('injectNewBooking caps at 3 pending', () {
      // Seed has 6 pending — already over the cap.
      expect(AppState.instance.injectNewBooking(), isNull);

      // Burn down to exactly 3 pending.
      for (var i = 0; i < 3; i++) {
        AppState.instance
            .declineBooking(AppState.instance.pendingBookings.first);
      }
      expect(AppState.instance.pendingBookings.length, 3);
      expect(AppState.instance.injectNewBooking(), isNull);

      // One more slot frees up.
      AppState.instance
          .declineBooking(AppState.instance.pendingBookings.first);
      final injected = AppState.instance.injectNewBooking();
      expect(injected, isNotNull);
      expect(injected!.status, GigBookingStatus.incoming);
      expect(AppState.instance.pendingBookings.length, 3);
      expect(AppState.instance.pendingBookings.first.id, injected.id);
    });
  });

  group('sign out', () {
    test('resets feed, job and profile', () {
      final booking = AppState.instance.pendingBookings.first;
      AppState.instance.acceptBooking(booking);
      AppState.instance.completeJob();

      AppState.instance.signOut();

      expect(AppState.instance.pendingBookings.length, 6);
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
