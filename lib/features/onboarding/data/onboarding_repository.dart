import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/models/onboarding/onboarding_application.dart';
import '../../../../core/models/onboarding/onboarding_category.dart';
import '../../../../core/models/onboarding/onboarding_city.dart';
import '../../../../core/models/onboarding/onboarding_personal_details.dart';
import '../../../../core/models/onboarding/onboarding_services.dart';
import '../../../../core/models/onboarding/onboarding_zone.dart';
import '../../../../core/models/onboarding/otp_response.dart';
import '../../../../core/models/onboarding/otp_verify_response.dart';
import '../../../../core/models/onboarding/token_response.dart';
import '../../../core/data/api_client.dart';
import '../../../core/data/storage_service.dart';

class OnboardingRepository {
  OnboardingRepository._(this._apiClient, this._storage);

  factory OnboardingRepository.create(
    ApiClient apiClient,
    StorageService storage,
  ) {
    return OnboardingRepository._(apiClient, storage);
  }

  static OnboardingRepository? _instance;
  static OnboardingRepository get instance {
    if (_instance == null) {
      throw StateError(
        'OnboardingRepository not initialized. '
        'Call OnboardingRepository.initialize() first.',
      );
    }
    return _instance!;
  }

  static void initialize(
    ApiClient apiClient,
    StorageService storage,
  ) {
    _instance ??= OnboardingRepository.create(apiClient, storage);
  }

  final ApiClient _apiClient;
  final StorageService _storage;

  Dio get dio => _apiClient.dio;
  Dio get _dio => dio;

  Future<bool> get hasTokens async {
    final access = await _storage.getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> clearTokens() => _storage.clearTokens();

  // ─── Step 1 ───────────────────────────────────────────────────────────────

  Future<OtpRequestResponse> requestOtp(String phone) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor-onboarding/otp/request',
      data: {'phone': phone},
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OtpRequestResponse.fromJson(data);
  }

  // ─── Step 2 ───────────────────────────────────────────────────────────────

  Future<OtpVerifyResponse> verifyOtp(String phone, String otp) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor-onboarding/otp/verify',
      data: {'phone': phone, 'otp': otp},
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    final verify = OtpVerifyResponse.fromJson(data);
    await _storage.saveTokens(verify.accessToken, verify.refreshToken);
    return verify;
  }

  // ─── Step 3 ───────────────────────────────────────────────────────────────

  Future<OnboardingApplication> getApplication() async {
    final resp = await _dio.get<Map<String, dynamic>>('/vendor-onboarding');
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  Future<OnboardingApplication> savePersonalDetails(
    OnboardingPersonalDetails details,
  ) async {
    final resp = await _dio.put<Map<String, dynamic>>(
      '/vendor-onboarding/personal-details',
      data: details.toJson(),
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  Future<OnboardingApplication> saveProfilePhoto(String filePath) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'photo': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split(Platform.pathSeparator).last,
      ),
    });
    final resp = await _dio.put<Map<String, dynamic>>(
      '/vendor-onboarding/profile-photo',
      data: formData,
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  Future<OnboardingApplication> saveServices(
    OnboardingServices services,
  ) async {
    final resp = await _dio.put<Map<String, dynamic>>(
      '/vendor-onboarding/services',
      data: services.toJson(),
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  Future<OnboardingApplication> saveAadhaar({
    required String number,
    required String nameOnDocument,
    String? frontPath,
    String? backPath,
  }) async {
    final fields = <String, dynamic>{
      'number': number,
      'nameOnDocument': nameOnDocument,
    };
    if (frontPath != null) {
      fields['front'] = await MultipartFile.fromFile(
        frontPath,
        filename: frontPath.split(Platform.pathSeparator).last,
      );
    }
    if (backPath != null) {
      fields['back'] = await MultipartFile.fromFile(
        backPath,
        filename: backPath.split(Platform.pathSeparator).last,
      );
    }
    final formData = FormData.fromMap(fields);
    final resp = await _dio.put<Map<String, dynamic>>(
      '/vendor-onboarding/documents/aadhaar',
      data: formData,
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  Future<OnboardingApplication> savePan({
    required String number,
    required String nameOnDocument,
    String? frontPath,
    String? backPath,
  }) async {
    final fields = <String, dynamic>{
      'number': number,
      'nameOnDocument': nameOnDocument,
    };
    if (frontPath != null) {
      fields['front'] = await MultipartFile.fromFile(
        frontPath,
        filename: frontPath.split(Platform.pathSeparator).last,
      );
    }
    if (backPath != null) {
      fields['back'] = await MultipartFile.fromFile(
        backPath,
        filename: backPath.split(Platform.pathSeparator).last,
      );
    }
    final formData = FormData.fromMap(fields);
    final resp = await _dio.put<Map<String, dynamic>>(
      '/vendor-onboarding/documents/pan',
      data: formData,
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  Future<OnboardingApplication> saveBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifsc,
    required String bankName,
    required String accountType,
    String? branchName,
    String? upiId,
    String? proofPath,
  }) async {
    final fields = <String, dynamic>{
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifsc': ifsc,
      'bankName': bankName,
      'accountType': accountType,
    };
    if (branchName != null && branchName.isNotEmpty) {
      fields['branchName'] = branchName;
    }
    if (upiId != null && upiId.isNotEmpty) {
      fields['upiId'] = upiId;
    }
    if (proofPath != null) {
      fields['proof'] = await MultipartFile.fromFile(
        proofPath,
        filename: proofPath.split(Platform.pathSeparator).last,
      );
    }
    final formData = FormData.fromMap(fields);
    final resp = await _dio.put<Map<String, dynamic>>(
      '/vendor-onboarding/bank-details',
      data: formData,
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<OnboardingApplication> submitApplication() async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/vendor-onboarding/submit',
      data: const <String, dynamic>{},
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  // ─── Step 4 ───────────────────────────────────────────────────────────────

  Future<OnboardingApplication> getStatus() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/vendor-onboarding/status',
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return OnboardingApplication.fromJson(data);
  }

  // ─── Dropdown data ─────────────────────────────────────────────────────────

  Future<List<OnboardingCity>> getCities() async {
    final resp = await _dio.get<Map<String, dynamic>>('/zones/cities');
    final data = resp.data?['data'] as List<dynamic>?;
    if (data == null) return <OnboardingCity>[];
    return data
        .map((c) => OnboardingCity.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<OnboardingZone>> getZones(String cityId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/zones',
      queryParameters: <String, dynamic>{'cityId': cityId},
    );
    final data = resp.data?['data'] as List<dynamic>?;
    if (data == null) return <OnboardingZone>[];
    return data
        .map((z) => OnboardingZone.fromJson(z as Map<String, dynamic>))
        .toList();
  }

  Future<List<OnboardingCategory>> getCategories() async {
    final resp = await _dio.get<Map<String, dynamic>>('/categories');
    final data = resp.data?['data'] as List<dynamic>?;
    if (data == null) return <OnboardingCategory>[];
    return data
        .map((c) => OnboardingCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ─── Token refresh ─────────────────────────────────────────────────────────

  Future<TokenResponse> refreshTokens(String refreshToken) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = resp.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }
    return TokenResponse.fromJson(data);
  }
}
