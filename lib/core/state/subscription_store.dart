import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feed/data/rss_sources.dart';

part 'subscription_store.g.dart';

/// 订阅状态：持久化用户已订阅的源 id 集合
///
/// 订阅页切换、关注 tab 取源均依赖此 provider。
/// 首次安装时用默认源初始化，之后完全由用户控制。
@Riverpod(keepAlive: true)
class SubscriptionStore extends _$SubscriptionStore {
  static const _kSubscribed = 'subscribed_source_ids';
  static const _kInited = 'subscribed_inited';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final inited = prefs.getBool(_kInited) ?? false;
    Set<String> ids;
    if (inited) {
      ids = (prefs.getStringList(_kSubscribed) ?? []).toSet();
    } else {
      // 首次：用默认订阅源初始化
      ids = RssSources.defaultSubscribedIds.toSet();
      await prefs.setStringList(_kSubscribed, ids.toList());
      await prefs.setBool(_kInited, true);
    }
    state = ids;
  }

  bool isSubscribed(String sourceId) => state.contains(sourceId);

  Future<void> toggle(String sourceId) async {
    final prefs = await SharedPreferences.getInstance();
    final next = Set<String>.from(state);
    if (!next.add(sourceId)) next.remove(sourceId);
    state = next;
    await prefs.setStringList(_kSubscribed, next.toList());
  }

  /// 已订阅的源对象列表
  List<RssSource> get subscribedSources =>
      state.map(RssSources.byId).whereType<RssSource>().toList();
}
