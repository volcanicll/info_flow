import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/core/logging/logger.dart';
import 'package:info_flow/core/storage/kv_storage.dart';

part 'smart_money_watch_store.g.dart';

/// 聪明钱关注列表：用户关注的大户 handle（上游区分大小写，原样存储）。
///
/// 聪明钱页一键关注/取关，后台告警轮询据此决定是否推送该大户的成交；
/// 持久化到 SharedPreferences，与 [CryptoWatchlistStore] 同一套模式。
@Riverpod(keepAlive: true)
class SmartMoneyWatchStore extends _$SmartMoneyWatchStore {
  static const _kWatch = 'smart_money_watchlist';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<String> build() {
    return _prefs.getStringList(_kWatch) ?? [];
  }

  bool isWatched(String handle) => state.contains(handle);

  /// 切换关注状态：加入时追加到末尾，移除时保留其余顺序。
  Future<void> toggle(String handle) async {
    final list = List<String>.from(state);
    if (list.contains(handle)) {
      list.remove(handle);
    } else {
      list.add(handle);
    }
    state = list;
    await _persist(list);
  }

  Future<void> _persist(List<String> list) async {
    try {
      await _prefs.setStringList(_kWatch, list);
    } catch (e) {
      // 磁盘写入失败不冒泡到 UI：内存状态保留，下次启动回退
      ref.read(loggerProvider).w('聪明钱关注列表保存失败', error: e);
    }
  }
}
