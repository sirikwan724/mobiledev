import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class ThemeModeController extends ChangeNotifier {
  ThemeModeController() {
    _isDark = web.window.localStorage.getItem(_storageKey) == 'dark';
  }

  static const _storageKey = 'room_booking_theme';
  late bool _isDark;

  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    web.window.localStorage.setItem(_storageKey, _isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
