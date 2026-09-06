import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/core/logging/logger.dart';
import 'package:info_flow/core/storage/kv_storage.dart';

part 'crypto_watchlist_store.g.dart';

/// 加密自选列表：用户关注的币种（大写简称，如 BTC / SOL）。
///
/// 用 List 保持用户添加顺序（UI 按此顺序渲染），全部持久化到
/// SharedPreferences。所有页面 watch 此 provider，任一处加星/去星
/// 自动通知全部 watcher，实现雷达页、脉搏页、详情页联动。
@Riverpod(keepAlive: true)
class CryptoWatchlistStore extends _$CryptoWatchlistStore {
  static const _kWatchlist = 'crypto_watchlist';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<String> build() {
    final list = _prefs.getStringList(_kWatchlist) ?? [];
    return list;
  }

  bool isWatched(String coin) => state.contains(coin.toUpperCase());

  /// 切换关注状态：加入时追加到末尾，移除时保留其余顺序。
  Future<void> toggle(String coin) async {
    final sym = coin.toUpperCase();
    final list = List<String>.from(state);
    if (list.contains(sym)) {
      list.remove(sym);
    } else {
      list.add(sym);
    }
    state = list;
    await _persist(list);
  }

  Future<void> remove(String coin) async {
    final sym = coin.toUpperCase();
    final list = List<String>.from(state)..remove(sym);
    state = list;
    await _persist(list);
  }

  Future<void> _persist(List<String> list) async {
    try {
      await _prefs.setStringList(_kWatchlist, list);
    } catch (e) {
      // 磁盘写入失败不冒泡到 UI：内存状态保留，下次启动回退
      ref.read(loggerProvider).w('自选列表保存失败', error: e);
    }
  }
}
