import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_service.dart';
import '../domain/models/price_alert.dart';
import 'market_repository.dart';
import 'price_alert_store.dart';

part 'price_alerts.g.dart';

/// 代币价格提醒后台引擎：60s 轮询 Binance 现价，命中规则即本地推送。
///
/// 规则来自 [PriceAlertStore]，触发语义一次性（命中即停用，列表里可重新
/// 启用）。规则是显式阈值、基线在创建/重启用时落盘，因此无需首轮建基线，
/// 启动后稍作延迟即可补推停机期间已触发的条件。
/// 受「强信号推送」总开关约束；指纹（含代数）去重兜底持久化写失败的情况。
@Riverpod(keepAlive: true)
class PriceAlerts extends _$PriceAlerts {
  Timer? _timer;
  Timer? _first;

  static const _pollInterval = Duration(seconds: 60);
  static const _firstScanDelay = Duration(seconds: 5);
  static const _maxPerNotify = 3;

  @override
  void build() {
    ref.onDispose(() {
      _timer?.cancel();
      _first?.cancel();
    });
    _first = Timer(_firstScanDelay, _check);
    _timer = Timer.periodic(_pollInterval, (_) => _check());
  }

  Future<void> _check() async {
    if (!ref.read(signalNotifyPrefProvider)) return;
    final store = ref.read(priceAlertStoreProvider.notifier);
    final alerts = ref
        .read(priceAlertStoreProvider)
        .where((a) => a.enabled)
        .toList();
    if (alerts.isEmpty) return;
    try {
      final prices = await ref
          .read(marketRepositoryProvider)
          .fetchLastPrices(alerts.map((a) => a.symbol).toList());
      if (prices.isEmpty) return;

      final fired = <PriceAlert>[];
      for (final a in alerts) {
        final p = prices[a.symbol];
        if (p != null && priceAlertShouldFire(a, p)) fired.add(a);
      }
      if (fired.isEmpty) return;

      // 先停用（防重复触发的第一道闸），指纹去重兜底持久化写失败
      for (final a in fired) {
        await store.markTriggered(a.id);
      }
      final pref = ref.read(signalNotifyPrefProvider.notifier);
      final fresh = pref.markSeen(
        fired.map(priceAlertFingerprint).toList(),
        category: 'pa',
      );
      if (fresh.isEmpty) return;

      ref.read(notificationServiceProvider).showPriceAlert(
            title: '价格提醒 ${fresh.length} 条触发',
            body: fired
                .take(_maxPerNotify)
                .map(priceAlertDescription)
                .join('  '),
            payload: '/coin/${fired.first.symbol}',
          );
    } catch (_) {
      // 告警轮询失败静默：下一轮继续
    }
  }
}
