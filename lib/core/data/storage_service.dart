import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService(this._storage);
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _accessTokenExpiresAtKey = 'access_token_expires_at';

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<DateTime?> getAccessTokenExpiresAt() async {
    final value = await _storage.read(key: _accessTokenExpiresAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  Future<void> saveTokens(
    String access,
    String refresh, {
    int accessTokenExpiresIn = 900,
  }) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
    await _storage.write(
      key: _accessTokenExpiresAtKey,
      value: DateTime.now()
          .toUtc()
          .add(Duration(seconds: accessTokenExpiresIn))
          .toIso8601String(),
    );
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessTokenExpiresAtKey);
  }
}
