import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kRefreshToken = 'arise_refresh_token';

class AuthStorage {
  final FlutterSecureStorage _storage;
  String? _accessToken;

  AuthStorage(this._storage);

  // Access token lives in memory only — never persisted to disk
  String? get accessToken => _accessToken;
  void cacheAccessToken(String token) => _accessToken = token;
  void clearAccessToken() => _accessToken = null;

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> clearAll() async {
    _accessToken = null;
    await _storage.delete(key: _kRefreshToken);
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ));
});
