import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'kv_storage.g.dart';

const _keyThemeMode = 'theme_mode';
const _keyFontSize = 'font_size';

/// Must be set from main() before runApp to avoid theme flash
SharedPreferences? _prefs;

void initPrefs(SharedPreferences p) => _prefs = p;

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    if (_prefs != null) {
      final saved = _prefs!.getString(_keyThemeMode);
      if (saved != null) {
        return ThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => ThemeMode.system,
        );
      }
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs?.setString(_keyThemeMode, mode.name);
  }
}

@riverpod
class FontSizeNotifier extends _$FontSizeNotifier {
  @override
  double build() {
    if (_prefs != null) {
      return _prefs!.getDouble(_keyFontSize) ?? 16.0;
    }
    return 16.0;
  }

  Future<void> setFontSize(double size) async {
    state = size.clamp(12.0, 24.0);
    await _prefs?.setDouble(_keyFontSize, size);
  }
}
