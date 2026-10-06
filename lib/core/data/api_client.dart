import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/onboarding/token_response.dart';
import 'storage_service.dart';

const _baseUrl = 'https://home-services-backend-7cyx.onrender.com/api/v1';

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(_refreshInterceptor);

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  final StorageService _storage;
  late final Dio _dio;

  Dio get dio => _dio;
  bool get isDemo => _baseUrl.contains('mrbob.example.com') || _baseUrl.isEmpty;

  Future<void> _addAuthHeader(RequestOptions options) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Interceptor get _authInterceptor {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        await _addAuthHeader(options);
        return handler.next(options);
      },
    );
  }

  Interceptor get _refreshInterceptor {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final response = error.response;
        if (response?.statusCode != 401) {
          return handler.next(error);
        }

        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _storage.clearTokens();
          return handler.next(error);
        }

        try {
          final resp = await _dio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Content-Type': 'application/json'}),
          );

          final data = resp.data?['data'] as Map<String, dynamic>?;
          if (data == null) {
            await _storage.clearTokens();
            return handler.next(error);
          }

          final tokenResponse = TokenResponse.fromJson(data);
          await _storage.saveTokens(
            tokenResponse.accessToken,
            tokenResponse.refreshToken,
          );

          error.requestOptions.headers['Authorization'] =
              'Bearer ${tokenResponse.accessToken}';

          final retry = await _dio.fetch(error.requestOptions);
          return handler.resolve(retry);
        } on DioException catch (_) {
          await _storage.clearTokens();
          return handler.next(error);
        } catch (_) {
          await _storage.clearTokens();
          return handler.next(error);
        }
      },
    );
  }
}
