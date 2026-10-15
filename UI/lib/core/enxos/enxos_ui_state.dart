import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnxosUiState extends ChangeNotifier {
  EnxosUiState._(this._preferences, {required bool isDark})
    : _isDark = isDark;

  static const _themePreference = 'enxos_theme';

  final SharedPreferences _preferences;
  bool _isDark;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  static Future<EnxosUiState> restore() async {
    final preferences = await SharedPreferences.getInstance();
    return EnxosUiState._(
      preferences,
      isDark: preferences.getString(_themePreference) == 'dark',
    );
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
    unawaited(
      _preferences.setString(_themePreference, _isDark ? 'dark' : 'light'),
    );
  }
}