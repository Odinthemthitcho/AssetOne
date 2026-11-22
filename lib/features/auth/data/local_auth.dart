import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage.dart';

final class LocalProfile {
  const LocalProfile(this.id, this.name, this.email, {this.isGuest = false});

  static const guest = LocalProfile('guest', 'Khách', '', isGuest: true);

  final String id;
  final String name;
  final String email;
  final bool isGuest;
}

final class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

final class ResetChallenge {
  ResetChallenge(this.email, this.demoCode, this.expires, this.resendAt);

  final String email;
  final String demoCode;
  final DateTime expires;
  final DateTime resendAt;
  int _attempts = 0;
  bool _verified = false;
}

final class LocalAuth {
  LocalAuth(this._storage);

  final LocalStorage _storage;
  final _random = Random.secure();
  static const _key = 'auth.v1';
  ResetChallenge? _reset;

  Future<({List<Map<String, dynamic>> users, String? session})> _read() async {
    final json = await _storage.read(_key);
    if (json == null) return (users: <Map<String, dynamic>>[], session: null);
    final data = jsonDecode(json) as Map<String, dynamic>;
    return (
      users: (data['users'] as List).cast<Map<String, dynamic>>(),
      session: data['session'] as String?,
    );
  }

  Future<void> _save(List<Map<String, dynamic>> users, String? session) =>
      _storage.write(_key, jsonEncode({'users': users, 'session': session}));

  String _token(int bytes) =>
      base64UrlEncode(List.generate(bytes, (_) => _random.nextInt(256)));

  LocalProfile _profile(Map<String, dynamic> user) => LocalProfile(
    user['id'] as String,
    user['name'] as String,
    user['email'] as String,
  );

  Future<LocalProfile?> restore() async {
    final data = await _read();
    final user = data.users.where((u) => u['id'] == data.session).firstOrNull;
    return user == null ? null : _profile(user);
  }

  Future<LocalProfile> register(
    String name,
    String email,
    String password,
  ) async {
    final normalized = email.trim().toLowerCase();
    if (!validEmail(normalized)) {
      throw const AuthException('Email không hợp lệ.');
    }
    if (name.trim().isEmpty) throw const AuthException('Nhập họ và tên.');
    _validatePassword(password);
    final data = await _read();
    if (data.users.any((u) => u['email'] == normalized)) {
      throw const AuthException('Email này đã có hồ sơ trên thiết bị.');
    }
    final salt = _token(16);
    final user = <String, dynamic>{
      'id': _token(18),
      'name': name.trim(),
      'email': normalized,
      'salt': salt,
      'hash': await _hash(password, salt),
    };
    await _save([...data.users, user], user['id'] as String);
    return _profile(user);
  }

  Future<LocalProfile> signIn(
    String email,
    String password, {
    required bool remember,
  }) async {
    final data = await _read();
    final normalized = email.trim().toLowerCase();
    final user = data.users.where((u) => u['email'] == normalized).firstOrNull;
    final hash = await _hash(password, user?['salt'] as String? ?? _token(16));
    if (user == null || !_same(hash, user['hash'] as String)) {
      throw const AuthException('Email hoặc mật khẩu không đúng.');
    }
    await _save(data.users, remember ? user['id'] as String : null);
    return _profile(user);
  }

  Future<void> signOut() async {
    final data = await _read();
    await _save(data.users, null);
    _reset = null;
  }

  Future<ResetChallenge> requestReset(String email) async {
    final normalized = email.trim().toLowerCase();
    final now = DateTime.now();
    if (_reset case final reset?
        when reset.email == normalized && now.isBefore(reset.resendAt)) {
      throw const AuthException('Vui lòng đợi trước khi yêu cầu mã mới.');
    }
    final data = await _read();
    if (!data.users.any((u) => u['email'] == normalized)) {
      throw const AuthException('Chưa có hồ sơ cục bộ dùng email này.');
    }
    return _reset = ResetChallenge(
      normalized,
      _random.nextInt(1000000).toString().padLeft(6, '0'),
      now.add(const Duration(minutes: 5)),
      now.add(const Duration(seconds: 45)),
    );
  }

  void verify(ResetChallenge reset, String code) {
    _checkChallenge(reset);
    if (reset._attempts >= 5) {
      throw const AuthException('Đã nhập sai 5 lần. Hãy yêu cầu mã mới.');
    }
    reset._attempts++;
    if (!_same(reset.demoCode, code.trim())) {
      throw const AuthException('Mã xác nhận không đúng.');
    }
    reset._verified = true;
  }

  Future<void> resetPassword(ResetChallenge reset, String password) async {
    _checkChallenge(reset);
    if (!reset._verified) throw const AuthException('Cần xác nhận mã trước.');
    _validatePassword(password);
    final data = await _read();
    final user = data.users.firstWhere((u) => u['email'] == reset.email);
    final salt = _token(16);
    user['salt'] = salt;
    user['hash'] = await _hash(password, salt);
    await _save(data.users, data.session == user['id'] ? null : data.session);
    _reset = null;
  }

  void _checkChallenge(ResetChallenge reset) {
    if (!identical(_reset, reset) || !DateTime.now().isBefore(reset.expires)) {
      throw const AuthException('Mã đã hết hiệu lực. Hãy yêu cầu mã mới.');
    }
  }

  static bool validEmail(String source) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(source.trim());

  static void _validatePassword(String password) {
    if (password.length < 8 || password.length > 128) {
      throw const AuthException('Mật khẩu cần từ 8 đến 128 ký tự.');
    }
  }

  static Future<String> _hash(String password, String salt) =>
      compute(_derive, (password: password, salt: salt));

  static bool _same(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
    }
    return difference == 0;
  }
}

String _derive(({String password, String salt}) input) {
  // PBKDF2-HMAC-SHA256, one 32-byte output block.
  final mac = Hmac(sha256, utf8.encode(input.password));
  var previous = mac.convert([
    ...base64Url.decode(input.salt),
    0,
    0,
    0,
    1,
  ]).bytes;
  final result = List<int>.of(previous);
  for (var round = 1; round < 210000; round++) {
    previous = mac.convert(previous).bytes;
    for (var i = 0; i < result.length; i++) {
      result[i] ^= previous[i];
    }
  }
  return base64UrlEncode(result);
}
