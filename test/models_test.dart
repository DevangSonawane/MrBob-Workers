import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:mrbob_partner/core/data/mock_worker.dart';
import 'package:mrbob_partner/core/data/skills_data.dart';
import 'package:mrbob_partner/core/models/gig_booking.dart';
import 'package:mrbob_partner/core/models/gig_worker_profile.dart';
import 'package:mrbob_partner/core/models/kyc_document.dart';
import 'package:mrbob_partner/core/models/job_session.dart';
import 'package:mrbob_partner/core/models/skill.dart';

void main() {
  group('Skill', () {
    test('catalog seeds 8 skills with unique ids', () {
      expect(skills.length, 8);
      expect(skills.map((s) => s.id).toSet().length, 8);
      for (final skill in skills) {
        expect(skill.title, isNotEmpty);
        expect(skill.subtitle, isNotEmpty);
        expect(skill.icon, isNotNull);
      }
    });

    test('skillById falls back to first skill', () {
      expect(skillById('plumbing').id, 'plumbing');
      expect(skillById('nope'), skills.first);
    });
  });

  group('GigBooking', () {
    final booking = GigBooking(
      id: 'GB1',
      skill: skills[1],
      customerName: 'Test User',
      customerRating: 4.8,
      addressLine: '1st Floor, Test Heights',
      landmark: 'near station',
      latitude: 19.29,
      longitude: 72.88,
      distanceKm: 2.4,
      etaMinutes: 8,
      slotLabel: 'Today, 4:30 PM',
      payout: 399,
      platformFee: 29,
      notes: 'Gate code 4412',
      durationLabel: '60 min',
    );

    test('totalPaid = payout + platformFee', () {
      expect(booking.totalPaid, 428);
    });

    test('defaults to incoming status', () {
      expect(booking.status, GigBookingStatus.incoming);
    });

    test('copyWith updates status only', () {
      final updated =
          booking.copyWith(status: GigBookingStatus.accepted);
      expect(updated.status, GigBookingStatus.accepted);
      expect(updated.payout, 399);
      expect(updated.customerName, 'Test User');
      expect(booking.status, GigBookingStatus.incoming);
    });

    test('status labels and isActive', () {
      expect(GigBookingStatus.inProgress.label, 'In progress');
      expect(GigBookingStatus.accepted.isActive, isTrue);
      expect(GigBookingStatus.completed.isActive, isFalse);
      expect(GigBookingStatus.declined.isActive, isFalse);
    });
  });

  group('KycDocument', () {
    test('aadhar masks all but last 4 digits', () {
      const doc = MockExtraction.aadhar;
      expect(doc.type, KycDocType.aadhar);
      expect(doc.label, 'Aadhar Card');
      expect(doc.maskedNumber, '•••• •••• 9012');
    });

    test('pan masks middle characters', () {
      const doc = MockExtraction.pan;
      expect(doc.type, KycDocType.pan);
      expect(doc.label, 'PAN Card');
      expect(doc.maskedNumber, 'AB•••••F');
    });

    test('pan regex contract: AAAAA9999A', () {
      expect(RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch('ABCDE1234F'),
          isTrue);
      expect(RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch('abcde1234f'),
          isFalse);
      expect(RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch('ABCDE1234'),
          isFalse);
    });
  });

  group('JobSession', () {
    test('elapsed is zero before start', () {
      final session = JobSession(
        booking: _dummyBooking(),
        phase: JobPhase.enroute,
      );
      expect(session.elapsed, Duration.zero);
    });

    test('elapsed spans startedAt to completedAt', () {
      final start = DateTime(2026, 1, 1, 10, 0);
      final end = DateTime(2026, 1, 1, 10, 47);
      final session = JobSession(
        booking: _dummyBooking(),
        phase: JobPhase.completed,
        startedAt: start,
        completedAt: end,
      );
      expect(session.elapsed, const Duration(minutes: 47));
    });

    test('copyWith carries timestamps forward', () {
      final arrivedAt = DateTime(2026, 1, 1, 9, 55);
      final session = JobSession(
        booking: _dummyBooking(),
        phase: JobPhase.arrived,
        arrivedAt: arrivedAt,
      );
      final advanced = session.copyWith(phase: JobPhase.otpVerified);
      expect(advanced.phase, JobPhase.otpVerified);
      expect(advanced.arrivedAt, arrivedAt);
      expect(advanced.booking.id, session.booking.id);
    });
  });

  group('GigWorkerProfile', () {
    test('copyWith updates skills and kyc', () {
      const profile = GigWorkerProfile();
      final updated = profile.copyWith(
        name: 'Ramesh',
        skills: skills.sublist(0, 3),
        kycStatus: KycStatus.verified,
      );
      expect(updated.name, 'Ramesh');
      expect(updated.skills.length, 3);
      expect(updated.isKycVerified, isTrue);
      expect(profile.isKycVerified, isFalse);
    });

    test('clearKycDocument drops the document', () {
      const profile = GigWorkerProfile(
        kycDocument: MockExtraction.aadhar,
        kycStatus: KycStatus.verified,
      );
      final cleared = profile.copyWith(clearKycDocument: true);
      expect(cleared.kycDocument, isNull);
      expect(cleared.kycStatus, KycStatus.verified);
    });
  });
}

GigBooking _dummyBooking() {
  return GigBooking(
    id: 'GB_TEST',
    skill: const Skill(
      id: 'test',
      title: 'Test',
      subtitle: 'test',
      icon: LucideIcons.wrench,
      color: Color(0xFFFFF8E8),
    ),
    customerName: 'Test',
    customerRating: 5.0,
    addressLine: 'Test',
    landmark: 'test',
    latitude: 19.2836,
    longitude: 72.8727,
    distanceKm: 1,
    etaMinutes: 5,
    slotLabel: 'ASAP',
    payout: 100,
    platformFee: 29,
    notes: 'test',
    durationLabel: '60 min',
  );
}
