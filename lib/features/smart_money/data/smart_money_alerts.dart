import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/state/smart_money_watch_store.dart';
import 'models/rht_models.dart';
import 'smart_money_repository.dart';

part 'smart_money_alerts.g.dart';

/// 聪明钱后台告警：60s 增量轮询 tape（since_id 游标），命中规则即本地推送。
///
/// 上游站点只提供被动看板，这里是 App 的代差能力：
/// - 关注的大户任何成交 ≥\$500；
/// - 无关注时仅追超大 KOL（粉丝 ≥20 万）的首买，避免打扰。
/// 首轮只建立游标不告警（避免启动时把历史成交当成新信号轰炸）。
@Riverpod(keepAlive: true)
class SmartMoneyAlerts extends _$SmartMoneyAlerts {
  Timer? _timer;
  int _lastId = 0;
  bool _bootstrapped = false;

  static const _pollInterval = Duration(seconds: 60);
  static const _watchMinUsd = 500.0;
  static const _megaFollowers = 200000;
  static const _megaMinUsd = 1000.0;

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(_pollInterval, (_) => _check());
  }

  Future<void> _check() async {
    if (!ref.read(signalNotifyPrefProvider)) return;
    try {
      final rows = await ref.read(rhtApiProvider).tape(
            limit: 60,
            sinceId: _lastId > 0 ? _lastId : null,
          );
      if (rows.isEmpty) return;
      rows.sort((a, b) => b.id.compareTo(a.id));
      if (!_bootstrapped) {
        _bootstrapped = true;
        _lastId = rows.first.id;
        return;
      }
      if (rows.first.id <= _lastId) return;
      final fresh = rows.where((r) => r.id > _lastId).toList();
      _lastId = rows.first.id;
      _notify(fresh);
    } catch (_) {
      // 告警轮询失败静默：下一轮继续
    }
  }

  void _notify(List<RhtFill> fills) {
    final watch = ref.read(smartMoneyWatchStoreProvider).toSet();
    final hits = <String>[];
    final fingerprints = <String>[];

    for (final f in fills) {
      final followed = watch.contains(f.handle);
      final megaFirstBuy = f.isNewPosition &&
          f.followers >= _megaFollowers &&
          f.usd >= _megaMinUsd;
      if (followed && f.usd >= _watchMinUsd) {
        hits.add(
            '${f.handle} ${f.isBuy ? '买入' : '卖出'} ${f.symbol} ${_usd(f.usd)}');
        fingerprints.add('sm|${f.id}');
      } else if (megaFirstBuy) {
        hits.add('${f.handle} 首买 ${f.symbol} ${_usd(f.usd)}');
        fingerprints.add('sm|${f.id}');
      }
    }
    if (hits.isEmpty) return;

    // 指纹去重：只提醒本轮新出现的成交
    final pref = ref.read(signalNotifyPrefProvider.notifier);
    final freshPrints = pref.markSeen(fingerprints);
    if (freshPrints.isEmpty) return;

    ref.read(notificationServiceProvider).showSignalAlert(
          title: '聪明钱异动 ${freshPrints.length} 笔',
          body: hits.take(3).join('  '),
          payload: '/smart-money',
        );
  }

  String _usd(double v) {
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e4) return '\$${v.round()}';
    return '\$${v.toStringAsFixed(0)}';
  }
}
