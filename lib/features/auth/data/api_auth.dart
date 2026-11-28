
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/storage/secure_token_storage.dart';
import 'local_auth.dart';

/// Authentication service using AssetOne Node.js Backend.
final class ApiAuth {
  ApiAuth({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
    required LocalStorage profileStorage,
  }) : _api = apiClient,
       _tokens = tokenStorage,
       _profileStorage = profileStorage;

  final ApiClient _api;
  final SecureTokenStorage _tokens;
  final LocalStorage _profileStorage;

  static const String _profileKey = 'auth.api.profile.v1';

  String? _sessionAccessToken;

  /// Register a new account in SQL Server through Backend.
  Future<LocalProfile> register(
    String name,
    String email,
    String password,
  ) async {
    return _authenticate(
      '/api/auth/register',
      {
        'fullName': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      remember: true,
    );
  }

  /// Sign in through Backend.
  Future<LocalProfile> signIn(
    String email,
    String password, {
    required bool remember,
  }) async {
    return _authenticate(
      '/api/auth/login',
      {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      remember: remember,
    );
  }

  Future<LocalProfile> _authenticate(
    String endpoint,
    Map<String, Object?> body, {
    required bool remember,
  }) async {
    try {
      final response = await _api.post(endpoint, body: body);

      final data = response['data'];
      if (data is! Map) {
        throw const AuthException('Backend trả về dữ liệu không hợp lệ.');
      }

      final user = data['user'];
      final token = data['accessToken'];

      if (user is! Map || token is! String || token.isEmpty) {
        throw const AuthException('Backend không trả về thông tin tài khoản hoặc JWT.');
      }

      final id = user['userId']?.toString();
      final name = user['fullName']?.toString();
      final email = user['email']?.toString();

      if (id == null || name == null || email == null) {
        throw const AuthException('Thiếu thông tin hồ sơ người dùng.');
      }

      final profile = LocalProfile(id, name, email);

      _sessionAccessToken = token;

      if (remember) {
        await _tokens.saveAccessToken(token);
      } else {
        await _tokens.deleteAccessToken();
      }

      await _profileStorage.write(
        _profileKey,
        jsonEncode({
          'id': profile.id,
          'name': profile.name,
          'email': profile.email,
        }),
      );

      return profile;
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  /// Restore a locally remembered session.
  Future<LocalProfile?> restore() async {
    final token = await _tokens.readAccessToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Invalid JWT');
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      if (payload is! Map || payload['exp'] is! num) {
        throw const FormatException('Invalid JWT claims');
      }

      final expiration = (payload['exp'] as num).toInt();

      if (expiration <=
          DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        await _clearLocalSession();
        return null;
      }

      final rawProfile = await _profileStorage.read(_profileKey);

      if (rawProfile == null) {
        await _clearLocalSession();
        return null;
      }

      final profile = jsonDecode(rawProfile);

      if (profile is! Map ||
          profile['id'] != payload['sub'] ||
          profile['email'] != payload['email']) {
        await _clearLocalSession();
        return null;
      }

      _sessionAccessToken = token;

      return LocalProfile(
        profile['id'] as String,
        profile['name'] as String,
        profile['email'] as String,
      );
    } on FormatException {
      await _clearLocalSession();
      return null;
    }
  }

  /// Get the current access token for authenticated API requests.
  Future<String?> getAccessToken() async {
    return _sessionAccessToken ?? await _tokens.readAccessToken();
  }

  /// Sign out locally and remove the stored JWT.
  Future<void> signOut() async {
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    _sessionAccessToken = null;
    await _tokens.deleteAccessToken();
    await _profileStorage.write(_profileKey, '');
  }

  /// Password reset is not implemented by the current Backend yet.
  Future<ResetChallenge> requestReset(String email) async {
    throw const AuthException(
      'Chức năng quên mật khẩu chưa được kết nối máy chủ.',
    );
  }

  void verify(ResetChallenge reset, String code) {
    throw const AuthException(
      'Chức năng xác nhận mã chưa được hỗ trợ.',
    );
  }

  Future<void> resetPassword(
    ResetChallenge reset,
    String password,
  ) async {
    throw const AuthException(
      'Chức năng đặt lại mật khẩu chưa được hỗ trợ.',
    );
  }
}
