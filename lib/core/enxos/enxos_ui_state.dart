import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnxosUiState extends ChangeNotifier {
  EnxosUiState() : _isDark = false;

  static const _themePreference = 'enxos_theme';

  SharedPreferences? _preferences;
  bool _isDark;
  bool _hasUserChangedTheme = false;
  bool _isDisposed = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_isDisposed) return;

      _preferences = preferences;
      if (_hasUserChangedTheme) {
        await _persistTheme(preferences);
      } else {
        _isDark = preferences.getString(_themePreference) == 'dark';
        notifyListeners();
      }
    } catch (error) {
      // O tema claro padrão mantém a interface disponível sem preferências locais.
      debugPrint('Não foi possível restaurar as preferências de tema: $error');
    }
  }

  void toggleTheme() {
    if (_isDisposed) return;
    _isDark = !_isDark;
    _hasUserChangedTheme = true;
    notifyListeners();
    final preferences = _preferences;
    if (preferences != null) unawaited(_persistTheme(preferences));
  }

  Future<void> _persistTheme(SharedPreferences preferences) async {
    try {
      await preferences.setString(_themePreference, _isDark ? 'dark' : 'light');
    } catch (error) {
      debugPrint('Não foi possível salvar a preferência de tema: $error');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
