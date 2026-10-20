import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob_partner/core/data/api_client.dart';
import 'package:mrbob_partner/core/data/storage_service.dart';
import 'package:mrbob_partner/core/models/gig_booking.dart';
import 'package:mrbob_partner/core/models/job_offer.dart';
import 'package:mrbob_partner/core/models/vendor_presence.dart';
import 'package:mrbob_partner/core/state/app_state.dart';
import 'package:mrbob_partner/features/feed/presentation/widgets/job_request_card.dart';
import 'package:mrbob_partner/features/vendor/data/vendor_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('H3 models', () {
    test('parses the presence payload', () {
      final presence = VendorPresence.fromJson(<String, dynamic>{
        'online': true,
        'latitude': 19.0636,
        'longitude': 72.83,
        'h3Cell': '88608b0b13fffff',
        'lastSeenAt': '2026-10-21T10:00:00.000Z',
        'onlineSince': '2026-10-21T09:30:00.000Z',
        'canReceiveOffers': true,
        'activeOffers': 1,
        'updateEverySeconds': 30,
      });

      expect(presence.online, isTrue);
      expect(presence.latitude, 19.0636);
      expect(presence.longitude, 72.83);
      expect(presence.h3Cell, '88608b0b13fffff');
      expect(presence.canReceiveOffers, isTrue);
      expect(presence.activeOffers, 1);
      expect(presence.updateEverySeconds, 30);
      expect(presence.hasPosition, isTrue);
      expect(presence.awaitingApproval, isFalse);
    });

    test('canReceiveOffers false marks the vendor as awaiting approval', () {
      final presence = VendorPresence.fromJson(<String, dynamic>{
        'online': true,
        'canReceiveOffers': false,
      });

      expect(presence.online, isTrue);
      expect(presence.awaitingApproval, isTrue);
    });

    test('a vendor that is not approved yet still parses', () {
      final presence = VendorPresence.fromJson(<String, dynamic>{
        'online': false,
        'canReceiveOffers': false,
        'updateEverySeconds': 30,
      });

      expect(presence.online, isFalse);
      expect(presence.updateEverySeconds, 30);
    });

    test('parses an available job with an offer', () {
      final booking = GigBooking.fromJson(<String, dynamic>{
        'id': 'caaae246-ba43-4642-9ce5-b3a8cfc0e332',
        'bookingNumber': 'BK-000943',
        'service': <String, dynamic>{
          'id': 'service-1',
          'name': 'Electrician',
          'tier': 'REPAIR',
        },
        'scheduledAt': '2026-10-21T04:59:00.000Z',
        'description': 'Fan not working',
        'price': 299,
        'paymentMode': 'PAY_AFTER_SERVICE',
        'area': <String, dynamic>{
          'city': <String, dynamic>{'name': 'Mumbai'},
          'zone': <String, dynamic>{'name': 'Bandra West'},
          'pincode': '400050',
        },
        'distanceKm': 0.23,
        'offer': <String, dynamic>{
          'expiresAt': '2026-10-21T10:01:00.000Z',
          'wave': 1,
        },
        'openToAll': false,
        'createdAt': '2026-10-21T10:00:00.000Z',
      });

      expect(booking.bookingNumber, 'BK-000943');
      expect(booking.paymentMode, 'PAY_AFTER_SERVICE');
      expect(booking.distanceKm, 0.23);
      expect(booking.distanceLabel, '0.2 km');
      expect(booking.addressLine, 'Bandra West, Mumbai, 400050');
      expect(booking.isOffered, isTrue);
      expect(booking.openToAll, isFalse);
      expect(booking.offer!.wave, 1);
      expect(booking.payout, 299);
    });

    test('a job without an offer keeps distance null and may be open to all', () {
      final booking = GigBooking.fromJson(<String, dynamic>{
        'id': 'job-2',
        'distanceKm': null,
        'openToAll': true,
      });

      expect(booking.distanceKm, isNull);
      expect(booking.distanceLabel, '');
      expect(booking.travelLabel, '');
      expect(booking.offer, isNull);
      expect(booking.isOffered, isFalse);
      expect(booking.openToAll, isTrue);
    });

    test('an offer counts down to its expiry', () {
      final expiresAt = DateTime.now().add(const Duration(seconds: 30));
      final offer = JobOffer(expiresAt: expiresAt, wave: 2);

      expect(offer.isExpired(DateTime.now()), isFalse);
      expect(offer.remaining(DateTime.now()).inSeconds, 29);
      expect(offer.isExpired(expiresAt.add(const Duration(seconds: 1))), isTrue);
      expect(
        offer.remaining(expiresAt.add(const Duration(seconds: 5))).inSeconds,
        0,
      );
    });
  });

  group('H3 vendor endpoints', () {
    late _RecordingAdapter adapter;
    late VendorRepository repository;

    setUp(() {
      final futureExpiry = DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String();
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'access_token': 'vendor-token',
        'refresh_token': 'refresh-token',
        'access_token_expires_at': futureExpiry,
      });
      adapter = _RecordingAdapter();
      final storage = StorageService(const FlutterSecureStorage());
      final apiClient = ApiClient(storage);
      apiClient.dio.httpClientAdapter = adapter;
      repository = VendorRepository.create(apiClient, storage);
    });

    test('getPresence calls GET /vendor/presence', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'online': true,
          'latitude': 19.0636,
          'longitude': 72.83,
          'h3Cell': '88608b0b13fffff',
          'canReceiveOffers': true,
          'activeOffers': 0,
          'updateEverySeconds': 30,
        },
      });

      final presence = await repository.getPresence();

      expect(adapter.lastOptions.method, 'GET');
      expect(adapter.lastOptions.path, '/vendor/presence');
      expect(presence.online, isTrue);
      expect(presence.h3Cell, '88608b0b13fffff');
    });

    test('updatePresence goes online with a position', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{'online': true, 'canReceiveOffers': true},
      });

      final presence = await repository.updatePresence(
        online: true,
        latitude: 19.0636,
        longitude: 72.83,
      );

      expect(adapter.lastOptions.method, 'PUT');
      expect(adapter.lastOptions.path, '/vendor/presence');
      expect(adapter.lastBody, contains('"online":true'));
      expect(adapter.lastBody, contains('"latitude":19.0636'));
      expect(adapter.lastBody, contains('"longitude":72.83'));
      expect(presence.online, isTrue);
    });

    test('updatePresence goes offline without a position', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{'online': false},
      });

      await repository.updatePresence(online: false);

      expect(adapter.lastOptions.method, 'PUT');
      expect(adapter.lastOptions.path, '/vendor/presence');
      expect(adapter.lastBody, contains('"online":false'));
      expect(adapter.lastBody, isNot(contains('latitude')));
    });

    test('a 400 on going online asks for a location', () async {
      adapter.enqueueError(
        400,
        <String, dynamic>{
          'success': false,
          'message': 'Send your location',
        },
      );

      expect(
        () => repository.updatePresence(online: true),
        throwsA(isA<LocationRequiredException>()),
      );
    });

    test('declineJob posts to /vendor/jobs/{id}/decline', () async {
      adapter.enqueue(<String, dynamic>{'data': <String, dynamic>{'declined': true}});

      await repository.declineJob('job-1');

      expect(adapter.lastOptions.method, 'POST');
      expect(adapter.lastOptions.path, '/vendor/jobs/job-1/decline');
    });

    test('a 409 on accept raises JobUnavailableException', () async {
      adapter.enqueueError(
        409,
        <String, dynamic>{
          'success': false,
          'message': 'Another vendor just took this job',
        },
      );

      expect(
        () => repository.acceptJob('job-1'),
        throwsA(
          isA<JobUnavailableException>().having(
            (error) => error.message,
            'message',
            'Another vendor just took this job',
          ),
        ),
      );
    });

    test('a 409 on decline raises JobUnavailableException', () async {
      adapter.enqueueError(
        409,
        <String, dynamic>{'success': false, 'message': 'Offer expired'},
      );

      expect(
        () => repository.declineJob('job-1'),
        throwsA(isA<JobUnavailableException>()),
      );
    });
  });

  group('H3 job card', () {
    testWidgets('an offer shows the countdown and a decline button',
        (tester) async {
      final booking = GigBooking.fromJson(<String, dynamic>{
        'id': 'job-1',
        'status': 'pending',
        'categoryId': 'plumbing',
        'distanceKm': 0.23,
        'offer': <String, dynamic>{
          'expiresAt': DateTime.now()
              .add(const Duration(seconds: 60))
              .toUtc()
              .toIso8601String(),
          'wave': 1,
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JobRequestCard(
              booking: booking,
              onAccept: () {},
              onDecline: () {},
              onViewDetails: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Offered to you'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.textContaining('0.2 km away'), findsOneWidget);
    });

    testWidgets('a job open to all shows the label and no decline',
        (tester) async {
      final booking = GigBooking.fromJson(<String, dynamic>{
        'id': 'job-2',
        'status': 'pending',
        'categoryId': 'plumbing',
        'openToAll': true,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JobRequestCard(
              booking: booking,
              onAccept: () {},
              onDecline: () {},
              onViewDetails: () {},
            ),
          ),
        ),
      );

      expect(find.text('Open to all vendors'), findsOneWidget);
      expect(find.text('Decline'), findsNothing);
      expect(find.text('Accept · ₹0'), findsOneWidget);
    });
  });

  group('H3 app state', () {
    late _RecordingAdapter adapter;
    late VendorRepository repository;

    setUp(() async {
      final futureExpiry = DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String();
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'access_token': 'vendor-token',
        'refresh_token': 'refresh-token',
        'access_token_expires_at': futureExpiry,
      });
      adapter = _RecordingAdapter();
      final storage = StorageService(const FlutterSecureStorage());
      final apiClient = ApiClient(storage);
      apiClient.dio.httpClientAdapter = adapter;
      repository = VendorRepository.create(apiClient, storage);

      // initialize() loads the profile, the presence, the assigned jobs and
      // the available jobs — in that order.
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'name': 'Ramesh Kumar',
          'skills': <String>['plumbing'],
        },
      });
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'online': false,
          'canReceiveOffers': true,
          'updateEverySeconds': 30,
        },
      });
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{'bookings': <Map<String, dynamic>>[]},
      });
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{'items': <Map<String, dynamic>>[]},
      });

      await AppState.instance.initialize(repository);
    });

    tearDown(() {
      AppState.instance.signOut();
    });

    test('reads the server presence on start', () {
      expect(AppState.instance.presence.value.online, isFalse);
      expect(AppState.instance.presence.value.updateEverySeconds, 30);
      expect(
        adapter.paths.where((path) => path == '/vendor/presence'),
        isNotEmpty,
      );
    });

    test('going offline calls PUT /vendor/presence', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{'online': false},
      });

      final ok = await AppState.instance.setOnline(false);

      expect(ok, isTrue);
      expect(adapter.lastOptions.method, 'PUT');
      expect(adapter.lastOptions.path, '/vendor/presence');
      expect(adapter.lastBody, contains('"online":false'));
      expect(AppState.instance.presence.value.online, isFalse);
    });

    test('a vendor that is online but not approved is flagged', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'online': true,
          'canReceiveOffers': false,
          'updateEverySeconds': 30,
        },
      });

      await AppState.instance.loadPresence();

      expect(AppState.instance.presence.value.online, isTrue);
      expect(AppState.instance.presence.value.awaitingApproval, isTrue);
    });

    test('the poll is skipped while the vendor is offline', () async {
      final before = adapter.requests;

      await AppState.instance.pollAvailableJobs();

      expect(adapter.requests, before);
    });

    test('the poll reloads the available jobs while online', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'online': true,
          'canReceiveOffers': true,
          'updateEverySeconds': 30,
        },
      });
      await AppState.instance.loadPresence();
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'job-9',
              'status': 'pending',
              'categoryId': 'plumbing',
              'distanceKm': 0.4,
            },
          ],
        },
      });

      await AppState.instance.pollAvailableJobs();

      expect(adapter.lastOptions.path, '/vendor/jobs/available');
      expect(AppState.instance.pendingBookings.single.id, 'job-9');
    });

    test('a 409 on accept drops the job and refreshes the list', () async {
      final booking = GigBooking.fromJson(<String, dynamic>{
        'id': 'job-9',
        'status': 'pending',
        'categoryId': 'plumbing',
      });
      AppState.instance.bookings.value = <GigBooking>[booking];
      adapter.enqueueError(
        409,
        <String, dynamic>{
          'success': false,
          'message': 'This job is no longer available',
        },
      );
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{'items': <Map<String, dynamic>>[]},
      });

      await expectLater(
        AppState.instance.acceptBooking(booking),
        throwsA(isA<JobUnavailableException>()),
      );

      expect(AppState.instance.pendingBookings, isEmpty);
      expect(
        AppState.instance.errorMessage.value,
        'This job is no longer available',
      );
    });

    test('declining an offer removes it from the feed', () async {
      final booking = GigBooking.fromJson(<String, dynamic>{
        'id': 'job-9',
        'status': 'pending',
        'categoryId': 'plumbing',
        'offer': <String, dynamic>{
          'expiresAt': DateTime.now()
              .add(const Duration(seconds: 60))
              .toUtc()
              .toIso8601String(),
          'wave': 1,
        },
      });
      AppState.instance.bookings.value = <GigBooking>[booking];
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{'declined': true},
      });

      await AppState.instance.declineBooking(booking);

      expect(adapter.lastOptions.method, 'POST');
      expect(adapter.lastOptions.path, '/vendor/jobs/job-9/decline');
      expect(AppState.instance.pendingBookings, isEmpty);
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter();

  final _responses = <Map<String, dynamic>>[];
  final List<String> paths = <String>[];
  int requests = 0;
  late RequestOptions lastOptions;
  String lastBody = '';

  void enqueue(Map<String, dynamic> body) => _responses.add(body);

  void enqueueError(int statusCode, Map<String, dynamic> body) {
    _responses.add(<String, dynamic>{
      '__statusCode': statusCode,
      ...body,
    });
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    lastOptions = options;
    paths.add(options.path);
    if (requestStream != null) {
      final bytes = await requestStream.expand((chunk) => chunk).toList();
      lastBody = utf8.decode(bytes);
    } else {
      lastBody = '';
    }
    final body = _responses.removeAt(0);
    final statusCode = body['__statusCode'];
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode is int ? statusCode : 200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
