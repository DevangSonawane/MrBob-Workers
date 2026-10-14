import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob_partner/core/data/api_client.dart';
import 'package:mrbob_partner/core/data/storage_service.dart';
import 'package:mrbob_partner/features/vendor/data/vendor_repository.dart';

void main() {
  group('VendorRepository', () {
    late _RecordingAdapter adapter;
    late VendorRepository repository;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'access_token': 'vendor-token',
        'refresh_token': 'refresh-token',
      });
      adapter = _RecordingAdapter();
      final storage = StorageService(const FlutterSecureStorage());
      final apiClient = ApiClient(storage);
      apiClient.dio.httpClientAdapter = adapter;
      repository = VendorRepository.create(apiClient, storage);
    });

    test('getProfile calls GET /vendor/profile with bearer token', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'name': 'Ramesh Kumar',
          'phone': '9876543210',
          'gender': 'Male',
          'serviceArea': 'Andheri East',
          'kycStatus': 'verified',
          'skills': <String>['plumbing'],
        },
      });

      final profile = await repository.getProfile();

      expect(adapter.lastOptions.method, 'GET');
      expect(adapter.lastOptions.path, '/vendor/profile');
      expect(
        adapter.lastOptions.headers['Authorization'],
        'Bearer vendor-token',
      );
      expect(profile.name, 'Ramesh Kumar');
      expect(profile.skills.single.id, 'plumbing');
      expect(profile.isKycVerified, isTrue);
    });

    test('updateProfile calls PATCH /vendor/profile with payload', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'name': 'Ramesh Kumar',
          'phone': '9876543210',
        },
      });

      await repository.updateProfile(<String, dynamic>{'name': 'Ramesh Kumar'});

      expect(adapter.lastOptions.method, 'PATCH');
      expect(adapter.lastOptions.path, '/vendor/profile');
      expect(adapter.lastBody, contains('"name":"Ramesh Kumar"'));
    });

    test(
      'deleteAccount calls DELETE /vendor/profile and clears tokens',
      () async {
        adapter.enqueue(<String, dynamic>{'data': <String, dynamic>{}});
        final storage = StorageService(const FlutterSecureStorage());

        await repository.deleteAccount();

        expect(adapter.lastOptions.method, 'DELETE');
        expect(adapter.lastOptions.path, '/vendor/profile');
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
      },
    );

    test('getMyJobs calls GET /vendor/bookings and parses list', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'bookings': <Map<String, dynamic>>[
            _bookingJson(id: 'BK1', status: 'assigned'),
            _bookingJson(id: 'BK2', status: 'completed'),
          ],
        },
      });

      final bookings = await repository.getMyJobs();

      expect(adapter.lastOptions.method, 'GET');
      expect(adapter.lastOptions.path, '/vendor/bookings');
      expect(bookings.map((booking) => booking.id), <String>['BK1', 'BK2']);
      expect(bookings.first.status.label, 'Assigned');
    });

    test('getAvailableJobs calls GET /vendor/jobs/available and parses list', () async {
      adapter.enqueue(<String, dynamic>{
        'data': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            _bookingJson(id: 'BK1', status: 'pending'),
            _bookingJson(id: 'BK2', status: 'pending'),
          ],
        },
      });

      final bookings = await repository.getAvailableJobs();

      expect(adapter.lastOptions.method, 'GET');
      expect(adapter.lastOptions.path, '/vendor/jobs/available');
      expect(bookings.map((booking) => booking.id), <String>['BK1', 'BK2']);
      expect(bookings.first.status.label, 'Pending');
    });

    test('getBookingDetails calls GET /vendor/bookings/{id}', () async {
      adapter.enqueue(<String, dynamic>{
        'data': _bookingJson(id: 'BK42', status: 'in_progress'),
      });

      final booking = await repository.getBookingDetails('BK42');

      expect(adapter.lastOptions.method, 'GET');
      expect(adapter.lastOptions.path, '/vendor/bookings/BK42');
      expect(booking.id, 'BK42');
      expect(booking.status.label, 'In Progress');
      expect(booking.customerName, 'Priya Shah');
    });
  });
}

Map<String, dynamic> _bookingJson({
  required String id,
  required String status,
}) {
  return <String, dynamic>{
    'id': id,
    'categoryId': 'plumbing',
    'customer': <String, dynamic>{'name': 'Priya Shah', 'rating': 4.7},
    'address': <String, dynamic>{
      'fullAddress': 'B-1202, Sunrise Towers',
      'landmark': 'Near metro station',
      'lat': 19.28,
      'lng': 72.87,
    },
    'distanceKm': 3.2,
    'etaMinutes': 12,
    'slotLabel': 'Today, 4:30 PM',
    'payout': 399,
    'platformFee': 29,
    'notes': 'Bring pipe sealant',
    'durationLabel': '60 min',
    'status': status,
  };
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter();

  final _responses = <Map<String, dynamic>>[];
  late RequestOptions lastOptions;
  String lastBody = '';

  void enqueue(Map<String, dynamic> body) => _responses.add(body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (requestStream != null) {
      final bytes = await requestStream.expand((chunk) => chunk).toList();
      lastBody = utf8.decode(bytes);
    } else {
      lastBody = '';
    }
    final body = _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}