
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for AssetOne authentication tokens.
final class SecureTokenStorage {
  SecureTokenStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'assetone.access_token.v1';

  /// Save JWT access token securely.
  Future<void> saveAccessToken(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Access token cannot be empty.');
    }

    await _storage.write(
      key: _accessTokenKey,
      value: token,
    );
  }

  /// Read JWT access token.
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  /// Delete JWT access token on logout.
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
