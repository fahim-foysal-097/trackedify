import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kPinHash = 'pin_hash';
  static const _kPinSalt = 'pin_salt';
  static const _kRecoveryHash = 'recovery_hash';
  static const _kRecoverySalt = 'recovery_salt';

  // generate random salt
  String _genSalt([int len = 16]) {
    final r = Random.secure();
    final bytes = List<int>.generate(len, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<void> setPin(String pin, {String? recoveryPassword}) async {
    final pinSalt = _genSalt();
    final pinHash = _sha256(pinSalt + pin);

    await _storage.write(key: _kPinSalt, value: pinSalt);
    await _storage.write(key: _kPinHash, value: pinHash);

    if (recoveryPassword != null && recoveryPassword.isNotEmpty) {
      final recSalt = _genSalt();
      final recHash = _sha256(recSalt + recoveryPassword);
      await _storage.write(key: _kRecoverySalt, value: recSalt);
      await _storage.write(key: _kRecoveryHash, value: recHash);
    }
  }

  Future<bool> verifyPin(String pin) async {
    final s = await _storage.read(key: _kPinSalt);
    final h = await _storage.read(key: _kPinHash);
    if (s == null || h == null) return false;
    final check = _sha256(s + pin);
    return check == h;
  }

  Future<bool> isPinSet() async {
    final h = await _storage.read(key: _kPinHash);
    return h != null;
  }

  Future<void> disablePin() async {
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kRecoverySalt);
    await _storage.delete(key: _kRecoveryHash);
  }

  Future<void> setRecoveryPassword(String recovery) async {
    final salt = _genSalt();
    final hash = _sha256(salt + recovery);
    await _storage.write(key: _kRecoverySalt, value: salt);
    await _storage.write(key: _kRecoveryHash, value: hash);
  }

  Future<bool> verifyRecoveryPassword(String recovery) async {
    final s = await _storage.read(key: _kRecoverySalt);
    final h = await _storage.read(key: _kRecoveryHash);
    if (s == null || h == null) return false;
    return _sha256(s + recovery) == h;
  }
}
