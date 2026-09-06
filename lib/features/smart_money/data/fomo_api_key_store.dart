import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/core/storage/kv_storage.dart';

part 'fomo_api_key_store.g.dart';

/// FOMO API Key（fomoapi.io，免费档 10,000 请求/月）。
///
/// 未配置时：多窗口收益榜仍可用（免 key，IP 限流），
/// 代币聪明钱持仓等按 key 计费的端点对应功能自动隐藏。
@Riverpod(keepAlive: true)
class FomoApiKeyStore extends _$FomoApiKeyStore {
  static const _key = 'fomo_api_key';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  String build() => _prefs.getString(_key) ?? '';

  bool get isConfigured => state.trim().isNotEmpty;

  Future<void> setKey(String value) async {
    state = value.trim();
    await _prefs.setString(_key, state);
  }
}
