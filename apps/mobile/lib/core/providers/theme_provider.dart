import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences.dart';

// ---------------------------------------------------------------------------
// Preferences provider — must be overridden in ProviderScope with a real
// AppPreferences instance that has already called init().
// ---------------------------------------------------------------------------

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError('appPreferencesProvider must be overridden in ProviderScope');
});

// ---------------------------------------------------------------------------
// themeModeProvider — persists to AppPreferences when mutated
// ---------------------------------------------------------------------------

final themeModeProvider = StateNotifierProvider<_ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  return _ThemeModeNotifier(prefs);
});

class _ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final AppPreferences _prefs;

  _ThemeModeNotifier(this._prefs) : super(_prefs.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
  }
}

// ---------------------------------------------------------------------------
// highContrastProvider — persists to AppPreferences when mutated
// ---------------------------------------------------------------------------

final highContrastProvider = StateNotifierProvider<_HighContrastNotifier, bool>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  return _HighContrastNotifier(prefs);
});

class _HighContrastNotifier extends StateNotifier<bool> {
  final AppPreferences _prefs;

  _HighContrastNotifier(this._prefs) : super(_prefs.getHighContrast());

  Future<void> setHighContrast(bool val) async {
    state = val;
    await _prefs.setHighContrast(val);
  }
}
