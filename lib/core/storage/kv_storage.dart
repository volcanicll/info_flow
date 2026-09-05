import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'kv_storage.g.dart';

const _keyThemeMode = 'theme_mode';
const _keyFontSize = 'font_size';

/// 应用启动时在 main() 中通过 ProviderScope.overrides 注入，
/// 保证所有 store 均可同步读取初始值，避免主题闪动与加载竞态。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider 必须在 main() 中 override',
  ),
);

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_keyThemeMode);
    if (saved != null) {
      return ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.dark,
      );
    }
    // 加密终端定位：默认深色，用户显式选过的主题优先
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_keyThemeMode, mode.name);
  }
}

@riverpod
class FontSizeNotifier extends _$FontSizeNotifier {
  @override
  double build() =>
      ref.watch(sharedPreferencesProvider).getDouble(_keyFontSize) ?? 16.0;

  Future<void> setFontSize(double size) async {
    state = size.clamp(12.0, 24.0);
    await ref.read(sharedPreferencesProvider).setDouble(_keyFontSize, state);
  }
}
