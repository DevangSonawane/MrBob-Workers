import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/onboarding/token_response.dart';
import 'storage_service.dart';

const _baseUrl = 'https://home-services-backend-7cyx.onrender.com/api/v1';
const _refreshPath = '/auth/refresh';
const _logoutPath = '/auth/logout';
const _retryKey = 'token_refresh_retried';

class ApiClient with WidgetsBindingObserver {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _refreshDio = Dio(_dio.options);
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
    // Only add observer if binding is initialized (avoids test failures)
    try {
      WidgetsBinding.instance.addObserver(this);
    } on StateError catch (_) {
      // Binding not initialized (e.g., in tests) — skip observer registration.
    }
  }

  final StorageService _storage;
  late final Dio _dio;
  late final Dio _refreshDio;
  Future<void>? _refreshInFlight;

  Dio get dio => _dio;
  bool get isDemo => _baseUrl.contains('mrbob.example.com') || _baseUrl.isEmpty;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshIfNeeded().catchError((_) {}));
    }
  }

  Future<void> refreshIfNeeded() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return;
    final expiry = await _storage.getAccessTokenExpiresAt();
    if (expiry == null ||
        expiry.difference(DateTime.now().toUtc()) <
            const Duration(seconds: 60)) {
      await _refreshOnce();
    }
  }

  bool _doesNotRequireAuth(RequestOptions options) =>
      options.path == _refreshPath ||
      options.path == _logoutPath ||
      options.path.contains('/otp/');

  Future<void> _addAuthHeader(RequestOptions options) async {
    if (_doesNotRequireAuth(options)) return;
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Interceptor get _authInterceptor {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_doesNotRequireAuth(options)) await refreshIfNeeded();
        await _addAuthHeader(options);
        return handler.next(options);
      },
    );
  }

  Interceptor get _refreshInterceptor {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final code = _errorCode(error.response);
        if (code == 'TOKEN_INVALID' || code == 'SESSION_EXPIRED') {
          await _storage.clearTokens();
          return handler.next(error);
        }
        if (code != 'TOKEN_EXPIRED' ||
            error.requestOptions.extra[_retryKey] == true ||
            _doesNotRequireAuth(error.requestOptions)) {
          return handler.next(error);
        }

        try {
          await _refreshOnce();
          error.requestOptions.extra[_retryKey] = true;
          await _addAuthHeader(error.requestOptions);
          return handler.resolve(await _dio.fetch(error.requestOptions));
        } on DioException catch (refreshError) {
          // Network and 5xx refresh failures retain stored tokens for retry.
          return handler.next(refreshError);
        }
      },
    );
  }

  String? _errorCode(Response<dynamic>? response) {
    final body = response?.data;
    if (body is! Map) return null;
    final details = body['details'];
    return details is Map ? details['code']?.toString() : null;
  }

  Future<void> _refreshOnce() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _performRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.clearTokens();
      throw DioException(
        requestOptions: RequestOptions(path: _refreshPath),
        type: DioExceptionType.cancel,
      );
    }
    try {
      final resp = await _refreshDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = resp.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          type: DioExceptionType.badResponse,
        );
      }
      final tokens = TokenResponse.fromJson(data);
      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          type: DioExceptionType.badResponse,
        );
      }
      await _storage.saveTokens(
        tokens.accessToken,
        tokens.refreshToken,
        accessTokenExpiresIn: tokens.accessTokenExpiresIn,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          _errorCode(error.response) == 'SESSION_EXPIRED') {
        await _storage.clearTokens();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final refreshToken = await _storage.getRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _refreshDio.post<void>(
          _logoutPath,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      }
    } finally {
      await _storage.clearTokens();
    }
  }
}
