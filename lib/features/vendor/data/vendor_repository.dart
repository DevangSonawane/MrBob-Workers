import 'package:dio/dio.dart';

import '../../../core/data/api_client.dart';
import '../../../core/data/storage_service.dart';
import '../../../core/models/gig_booking.dart';
import '../../../core/models/gig_worker_profile.dart';
import '../../../core/models/vendor_presence.dart';
import '../../../core/models/vendor_wallet.dart';
import '../../../core/models/vendor_dispute.dart';

/// The server rejected the action because the H3 offer is gone — it expired
/// or another vendor was faster. The app drops the job and refreshes.
class JobUnavailableException implements Exception {
  const JobUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The server refused to switch the vendor online without a position.
class LocationRequiredException implements Exception {
  const LocationRequiredException(this.message);

  final String message;

  @override
  String toString() => message;
}

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

  Future<List<GigBooking>> getAvailableJobs({
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor/jobs/available',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = _readData(resp);
    final list = _extractList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(GigBooking.fromJson)
        .toList(growable: false);
  }

  Future<GigBooking> getAvailableJob(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor/jobs/available/$id',
    );
    return GigBooking.fromJson(_readObject(resp));
  }

  /// H3 presence: the server keeps the vendor's online state, their last
  /// position and the H3 cell it maps to.
  Future<VendorPresence> getPresence() async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/presence');
    return VendorPresence.fromJson(_readObject(resp));
  }

  /// Goes the vendor online (with a position) or offline.
  Future<VendorPresence> updatePresence({
    required bool online,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        '/vendor/presence',
        data: <String, dynamic>{
          'online': online,
          'latitude': ?latitude,
          'longitude': ?longitude,
        },
      );
      return VendorPresence.fromJson(_readObject(resp));
    } on DioException catch (error) {
      if (error.response?.statusCode == 400) {
        throw LocationRequiredException(
          _errorMessage(error, 'Send your location'),
        );
      }
      rethrow;
    }
  }

  Future<GigBooking> acceptJob(String id) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/vendor/jobs/$id/accept',
      );
      return GigBooking.fromJson(_readObject(resp));
    } on DioException catch (error) {
      if (_isConflict(error)) {
        throw JobUnavailableException(
          _errorMessage(error, 'This job is no longer available'),
        );
      }
      rethrow;
    }
  }

  /// Hands an offered job back so the next wave can pick it up.
  Future<void> declineJob(String id) async {
    try {
      await _dio.post<Map<String, dynamic>>('/vendor/jobs/$id/decline');
    } on DioException catch (error) {
      if (_isConflict(error)) {
        throw const JobUnavailableException(
          'This offer has already expired',
        );
      }
      rethrow;
    }
  }

  Future<GigBooking> startJob(String id, String otp) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/jobs/$id/start',
      data: {'otp': otp},
    );
    return GigBooking.fromJson(_readObject(resp));
  }

  Future<GigBooking> verifyCompletionOtp(String id, String otp) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/jobs/$id/completion-otp',
      data: {'otp': otp},
    );
    return GigBooking.fromJson(_readObject(resp));
  }

  Future<GigBooking> uploadCompletionImages(
    String id,
    List<MultipartFile> images,
  ) async {
    final formData = FormData.fromMap({'images': images});
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/jobs/$id/completion-images',
      data: formData,
    );
    return GigBooking.fromJson(_readObject(resp));
  }

  Future<void> deleteCompletionImage(String id, String imageId) async {
    await _dio.delete<Map<String, dynamic>>(
      '/vendor/jobs/$id/completion-images/$imageId',
    );
  }

  Future<GigBooking> completeJob(String id) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/jobs/$id/complete',
    );
    return GigBooking.fromJson(_readObject(resp));
  }

  Future<List<GigBooking>> getMyJobs({
    String? status,
    String? scope,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) queryParams['status'] = status;
    if (scope != null) queryParams['scope'] = scope;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor/bookings',
      queryParameters: queryParams,
    );
    final data = _readData(resp);
    final list = _extractList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(GigBooking.fromJson)
        .toList(growable: false);
  }

  Future<GigBooking> getBookingDetails(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/bookings/$id');
    return GigBooking.fromJson(_readObject(resp));
  }

  Future<GigBooking> rateCustomer({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/bookings/$bookingId/rating',
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return GigBooking.fromJson(_readObject(resp));
  }

  Future<List<DisputeCategory>> getDisputeCategories() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor/disputes/categories',
    );
    final data = _readData(resp);
    return (data as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DisputeCategory.fromJson)
        .toList(growable: false);
  }

  Future<List<VendorDispute>> getDisputes({
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor/disputes',
      queryParameters: {'page': page, 'limit': limit},
    );
    return _extractList(_readData(resp))
        .whereType<Map<String, dynamic>>()
        .map(VendorDispute.fromJson)
        .toList(growable: false);
  }

  Future<VendorDispute> createDispute({
    required String type,
    required String category,
    required String subject,
    required String description,
    String? bookingId,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/disputes',
      data: {
        'type': type,
        'category': category,
        'subject': subject,
        'description': description,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
    return VendorDispute.fromJson(_readObject(resp));
  }

  Future<VendorDispute> getDispute(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/disputes/$id');
    return VendorDispute.fromJson(_readObject(resp));
  }

  Future<VendorDispute> replyToDispute(String id, String message) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/disputes/$id/messages',
      data: {'message': message},
    );
    return VendorDispute.fromJson(_readObject(resp));
  }

  Future<VendorDispute> closeDispute(String id) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor/disputes/$id/close',
    );
    return VendorDispute.fromJson(_readObject(resp));
  }

  Future<String> getCompletionImageUrl(String bookingId, String imageId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/bookings/$bookingId/completion-images/$imageId',
    );
    final data = _readData(resp);
    if (data is Map<String, dynamic> && data['url'] != null) {
      return data['url'] as String;
    }
    throw DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      type: DioExceptionType.badResponse,
    );
  }

  Future<void> recordPaymentCollected(String id, String method) async {
    await _dio.post<Map<String, dynamic>>(
      '/bookings/$id/payment/collect',
      data: {'method': method},
    );
  }

  Future<WalletSummary> getWallet() async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/wallet');
    return WalletSummary.fromJson(_readObject(resp));
  }

  Future<List<WalletTransaction>> getWalletTransactions({
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor/wallet/transactions',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (type case final type?) 'type': type,
        if (status case final status?) 'status': status,
      },
    );
    final data = _readData(resp);
    return _extractList(data)
        .whereType<Map<String, dynamic>>()
        .map(WalletTransaction.fromJson)
        .toList(growable: false);
  }

  Future<PendingWalletEarnings> getPendingWalletEarnings({
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor/wallet/pending',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = resp.data?['data'] ?? resp.data;
    if (data is Map<String, dynamic>) {
      return PendingWalletEarnings.fromJson(data);
    }
    throw DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      type: DioExceptionType.badResponse,
    );
  }

  Future<PayoutAccount> getPayoutAccount() async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor/payout-account');
    return PayoutAccount.fromJson(_readObject(resp));
  }

  Future<PayoutAccount> updatePayoutAccount(
    Map<String, dynamic> changes,
  ) async {
    final resp = await _dio.put<Map<String, dynamic>>(
      '/vendor/payout-account',
      data: changes,
    );
    return PayoutAccount.fromJson(_readObject(resp));
  }

  Object? _readData(Response<Map<String, dynamic>> resp) {
    if (resp.data case {'data': final data}) {
      return data;
    }
    if (resp.data case {'items': final items}) {
      return items;
    }
    return resp.data;
  }

  List<dynamic> _extractList(Object? data) {
    return switch (data) {
      final List<dynamic> items => items,
      final Map<String, dynamic> map when map['bookings'] is List<dynamic> =>
        map['bookings'] as List<dynamic>,
      final Map<String, dynamic> map when map['items'] is List<dynamic> =>
        map['items'] as List<dynamic>,
      final Map<String, dynamic> map when map['results'] is List<dynamic> =>
        map['results'] as List<dynamic>,
      _ => const <dynamic>[],
    };
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

  static bool _isConflict(DioException error) =>
      error.response?.statusCode == 409;

  static String _errorMessage(DioException error, String fallback) {
    final body = error.response?.data;
    if (body is Map) {
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    return fallback;
  }
}
