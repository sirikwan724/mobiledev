import 'package:flutter/foundation.dart';

import '../../../../core/auth/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// State + Business Logic ของการล็อกอิน — View ไม่คุยกับ AuthService ตรงๆ
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authService) {
    _restoreFuture = _restore();
  }

  final AuthService _authService;

  AuthStatus status = AuthStatus.unknown;
  String? userName;
  String? userEmail;
  String? errorMessage;
  bool isSigningIn = false;
  late final Future<void> _restoreFuture;

  Future<void> _restore() async {
    try {
      final restored = await _authService.tryRestoreSession();
      if (restored) {
        await _loadUserInfo();
        status = AuthStatus.authenticated;
      } else {
        status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      errorMessage = 'กู้คืนสถานะเข้าสู่ระบบไม่สำเร็จ: $e';
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// เริ่ม Authorization Code Flow — เบราว์เซอร์จะ redirect ออกจากแอปไปหน้า login ของ OIDC Server
  Future<void> signIn() async {
    isSigningIn = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authService.signIn();
      // หลังจากนี้เบราว์เซอร์จะ redirect ออกจากแอปไปหน้า OIDC Server
    } catch (e) {
      errorMessage = 'เริ่มการเข้าสู่ระบบไม่สำเร็จ: $e';
      isSigningIn = false;
      notifyListeners();
    }
  }

  /// เรียกจากหน้า /callback เพื่อแลก authorization code เป็น token
  Future<void> handleCallback(Uri callbackUri) async {
    await _restoreFuture;
    errorMessage = null;
    notifyListeners();
    try {
      final ok = await _authService.handleRedirectCallback(callbackUri);
      if (ok) {
        await _loadUserInfo();
        status = AuthStatus.authenticated;
      } else {
        errorMessage = 'ไม่พบรหัสยืนยันตัวตนจากเซิร์ฟเวอร์';
        status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      errorMessage = 'เข้าสู่ระบบไม่สำเร็จ: $e';
      status = AuthStatus.unauthenticated;
    }
    isSigningIn = false;
    notifyListeners();
  }

  Future<void> _loadUserInfo() async {
    try {
      final info = await _authService.getUserInfo();
      userName = info?.name ?? info?.preferredUsername;
      userEmail = info?.email;
    } catch (_) {
      // userinfo ดึงไม่ได้ก็ไม่ควรบล็อกการล็อกอิน — ปล่อยให้เป็น null
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    userName = null;
    userEmail = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
