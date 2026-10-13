import 'package:dio/dio.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/storage_service.dart';
import '../../../core/models/gig_booking.dart';
import '../../../core/models/gig_worker_profile.dart';

class VendorRepository {
  VendorRepository._(this._apiClient, this._storage);

  factory VendorRepository.create(ApiClient apiClient, StorageService storage) {
    return VendorRepository._(apiClient, storage);
  }

  static VendorRepository? _instance;
  static VendorRepository get instance {
    if (_instance == null) {
      throw StateError(
        'VendorRepository not initialized. '
        'Call VendorRepository.initialize() first.',
      );
    }
    return _instance!;
  }

  static void initialize(ApiClient apiClient, StorageService storage) {
    _instance ??= VendorRepository.create(apiClient, storage);
  }

  final ApiClient _apiClient;
  final StorageService _storage;

  Dio get _dio => _apiClient.dio;

  Future<GigWorkerProfile> getProfile() async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/profile');
    return GigWorkerProfile.fromJson(_readObject(resp));
  }

  Future<GigWorkerProfile> updateProfile(Map<String, dynamic> payload) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/vendor/profile',
      data: payload,
    );
    return GigWorkerProfile.fromJson(_readObject(resp));
  }

  Future<GigWorkerProfile> updateWorkerProfile(GigWorkerProfile profile) {
    return updateProfile(profile.toJson());
  }

  Future<void> deleteAccount() async {
    await _dio.delete<Map<String, dynamic>>('/vendor/profile');
    await _storage.clearTokens();
  }

  Future<List<GigBooking>> getBookings() async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/bookings');
    final data = _readData(resp);
    final list = switch (data) {
      final List<dynamic> items => items,
      final Map<String, dynamic> map when map['bookings'] is List<dynamic> =>
        map['bookings'] as List<dynamic>,
      final Map<String, dynamic> map when map['items'] is List<dynamic> =>
        map['items'] as List<dynamic>,
      final Map<String, dynamic> map when map['results'] is List<dynamic> =>
        map['results'] as List<dynamic>,
      _ => const <dynamic>[],
    };
    return list
        .whereType<Map<String, dynamic>>()
        .map(GigBooking.fromJson)
        .toList(growable: false);
  }

  Future<GigBooking> getBookingDetails(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/bookings/$id');
    return GigBooking.fromJson(_readObject(resp));
  }

  Object? _readData(Response<Map<String, dynamic>> resp) {
    if (resp.data case {'data': final data}) {
      return data;
    }
    return resp.data;
  }

  Map<String, dynamic> _readObject(Response<Map<String, dynamic>> resp) {
    final data = _readData(resp);
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      type: DioExceptionType.badResponse,
    );
  }
}
