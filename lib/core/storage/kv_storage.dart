import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'kv_storage.g.dart';

const _keyThemeMode = 'theme_mode';
const _keyFontSize = 'font_size';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return SharedPreferences.getInstance();
}

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final saved = prefs.getString(_keyThemeMode);
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_keyThemeMode, mode.name);
  }
}

@riverpod
class FontSizeNotifier extends _$FontSizeNotifier {
  @override
  double build() {
    _loadFontSize();
    return 16.0;
  }

  Future<void> _loadFontSize() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getDouble(_keyFontSize) ?? 16.0;
  }

  Future<void> setFontSize(double size) async {
    state = size.clamp(12.0, 24.0);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble(_keyFontSize, size);
  }
}
