import 'dart:math';

import 'package:openid_client/openid_client.dart';
// ใช้ package:web ตรงๆ (ไม่ใช้ openid_client_browser.dart เพราะตัวนั้นรองรับแค่ Implicit Flow
// แต่โจทย์ต้องการ Authorization Code Flow + PKCE ซึ่งปลอดภัยกว่าและเป็นมาตรฐานสำหรับ public client)
import 'package:web/web.dart' hide Credential, Client;

import 'secure_storage_service.dart';

/// เชื่อมต่อกับ OIDC Server (django-oidc-provider จากสัปดาห์ที่ 12) ด้วย
/// Authorization Code Flow + PKCE (RFC 7636) — ไม่มีการ hard-code รหัสผ่านในแอปเลย
///
/// รหัสผ่านผู้ใช้ถูกกรอกที่หน้า login ของ Django เท่านั้น แอปเห็นแค่ authorization code
/// ที่ redirect กลับมา แล้วแลกเป็น token ผ่าน /token/ endpoint
class AuthService {
  AuthService(this._storage);

  static final Uri _issuerUri = Uri.parse('http://127.0.0.1:8000');
  static const _clientId = 'flutter-web-app';
  static const _redirectUri = 'http://localhost:50000/callback';
  static const _postLogoutRedirectUri = 'http://localhost:50000/login';
  static const _scopes = ['openid', 'profile', 'email'];

  final SecureStorageService _storage;
  Credential? _credential;

  Future<Client> _createClient() async {
    final issuer = await Issuer.discover(_issuerUri);
    return Client(issuer, _clientId);
  }

  /// เรียกตอนแอปเริ่มทำงาน: พยายามกู้คืน session เดิมจาก secure storage
  /// เพื่อให้ปิดแอปแล้วเปิดใหม่ยังล็อกอินอยู่ (ตามสเปกสัปดาห์ที่ 13/16)
  Future<bool> tryRestoreSession() async {
    final json = await _storage.readCredential();
    if (json == null) return false;
    try {
      final credential = Credential.fromJson(json);
      // ขอ token ปัจจุบัน — ถ้า access token หมดอายุ จะ refresh ให้อัตโนมัติด้วย refresh_token
      await credential.getTokenResponse();
      _credential = credential;
      await _persist();
      return true;
    } catch (_) {
      await _storage.clear();
      _credential = null;
      return false;
    }
  }

  /// ขั้นตอนที่ 1 ของ Authorization Code Flow: redirect เบราว์เซอร์ไปหน้า login ของ Django
  Future<void> signIn() async {
    final client = await _createClient();
    final state = _randomString(24);
    final codeVerifier = _randomString(64);

    final flow = Flow.authorizationCodeWithPKCE(
      client,
      state: state,
      codeVerifier: codeVerifier,
      scopes: _scopes,
    )..redirectUri = Uri.parse(_redirectUri);

    // เก็บ state/verifier ไว้ใน sessionStorage ของเบราว์เซอร์ เพราะหน้าเว็บจะ reload
    // ทั้งหน้าตอน redirect กลับมา (แอป Flutter Web รีสตาร์ทใหม่ทั้งหมด)
    window.sessionStorage.setItem('oidc_state', state);
    window.sessionStorage.setItem('oidc_verifier', codeVerifier);

    // Keep the OIDC scopes explicit in the actual browser request. This also
    // makes the requested identity claims visible to the provider consent page.
    final authorizationUri = flow.authenticationUri;
    window.location.href = authorizationUri
        .replace(queryParameters: {
          ...authorizationUri.queryParameters,
          'scope': _scopes.join(' '),
        })
        .toString();
  }

  /// ขั้นตอนที่ 2: เรียกที่หน้า /callback เพื่อแลก authorization code เป็น token
  Future<bool> handleRedirectCallback(Uri callbackUri) async {
    final params = callbackUri.queryParameters;
    if (params['error'] != null) {
      throw Exception(params['error_description'] ?? params['error']);
    }
    if (!params.containsKey('code')) return false;

    final state = window.sessionStorage.getItem('oidc_state');
    final codeVerifier = window.sessionStorage.getItem('oidc_verifier');
    if (state == null || codeVerifier == null) {
      throw Exception('ไม่พบข้อมูล state ของการล็อกอิน — กรุณาล็อกอินใหม่');
    }

    final client = await _createClient();
    final flow = Flow.authorizationCodeWithPKCE(
      client,
      state: state,
      codeVerifier: codeVerifier,
      scopes: _scopes,
    )..redirectUri = Uri.parse(_redirectUri);

    _credential = await flow.callback(params);

    window.sessionStorage.removeItem('oidc_state');
    window.sessionStorage.removeItem('oidc_verifier');

    await _persist();
    return true;
  }

  bool get isSignedIn => _credential != null;

  /// คืน Access Token ล่าสุด (refresh ให้อัตโนมัติถ้าหมดอายุ) — ใช้แนบใน Authorization header
  Future<String?> get accessToken async {
    final credential = _credential;
    if (credential == null) return null;
    final token = await credential.getTokenResponse();
    await _persist();
    return token.accessToken;
  }

  Future<UserInfo?> getUserInfo() async {
    final credential = _credential;
    if (credential == null) return null;
    return credential.getUserInfo();
  }

  Future<void> signOut() async {
    final credential = _credential;
    final logoutUri = credential?.generateLogoutUrl(
      redirectUri: Uri.parse(_postLogoutRedirectUri),
    );

    _credential = null;
    await _storage.clear();

    if (logoutUri != null) {
      window.location.href = logoutUri.toString();
    }
  }

  Future<void> _persist() async {
    final credential = _credential;
    if (credential != null) {
      await _storage.writeCredential(credential.toJson());
    }
  }

  String _randomString(int length) {
    final random = Random.secure();
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
