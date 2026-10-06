import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// เก็บ OIDC credential (access/refresh/id token) แบบเข้ารหัสในเครื่อง
/// (Keychain บน iOS, Keystore บน Android, encrypted storage บนเว็บ)
class SecureStorageService {
  static const _credentialKey = 'oidc_credential';

  final _storage = const FlutterSecureStorage();

  Future<void> writeCredential(Map<String, dynamic> json) =>
      _storage.write(key: _credentialKey, value: jsonEncode(json));

  Future<Map<String, dynamic>?> readCredential() async {
    final raw = await _storage.read(key: _credentialKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _credentialKey);
}
