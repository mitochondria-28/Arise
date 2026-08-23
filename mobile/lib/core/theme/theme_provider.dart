import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'arise_theme_pref';

class ThemeNotifier extends Notifier<ThemeMode> {
  final String _initialPref;
  ThemeNotifier(this._initialPref);

  @override
  ThemeMode build() => _parse(_initialPref);

  Future<void> setTheme(String pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, pref);
    state = _parse(pref);
  }

  ThemeMode _parse(String s) {
    switch (s) {
      case 'dark':  return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      default:      return ThemeMode.system;
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  () => ThemeNotifier('system'),
);
