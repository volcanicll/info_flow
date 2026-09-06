import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_service.dart';
import 'newsnow_repository.dart';

part 'breakout_alerts.g.dart';

/// 单条破圈命中的通知指纹：`bo|平台|标题`。
///
/// 标题即指纹——同一话题反复上榜不重复打扰；话题掉榜后再上榜
/// 也因指纹留存而保持安静，直到被更新的指纹挤出上限。
List<String> breakoutFingerprints(List<BreakoutHit> hits) {
  return hits.map((h) => 'bo|${h.platform}|${h.article.title}').toList();
}

/// 破圈后台告警：10 分钟轮询一次微博/知乎/头条热榜，命中 Web3
/// 关键词且未推送过即本地推送。
///
/// 大众热榜更新节奏为分钟级，且 NewsNow 服务端缓存约 30 分钟，
/// 轮询间隔取 10 分钟足够。首轮只建立指纹基线不告警（避免启动时
/// 把既有热榜当成新信号轰炸）；受「强信号推送」总开关约束。
@Riverpod(keepAlive: true)
class BreakoutAlerts extends _$BreakoutAlerts {
  Timer? _timer;
  Timer? _first;
  bool _bootstrapped = false;

  static const _pollInterval = Duration(minutes: 10);
  static const _firstScanDelay = Duration(seconds: 8);
  static const _maxPerNotify = 3;

  @override
  void build() {
    ref.onDispose(() {
      _timer?.cancel();
      _first?.cancel();
    });
    // 启动后稍作延迟做首轮扫描（建立基线或推送停机期间的新命中），
    // 不等 10 分钟周期：上游服务端缓存约 30 分钟，首轮成本可忽略。
    _first = Timer(_firstScanDelay, _check);
    _timer = Timer.periodic(_pollInterval, (_) => _check());
  }

  Future<void> _check() async {
    if (!ref.read(signalNotifyPrefProvider)) return;
    try {
      final hits = await ref.read(newsNowRepositoryProvider).fetchBreakoutHits();
      if (hits.isEmpty) return;

      final pref = ref.read(signalNotifyPrefProvider.notifier);
      final fresh = pref.markSeen(breakoutFingerprints(hits));
      if (!_bootstrapped) {
        // 首轮仅建立基线：把当前热榜记为已见，不打扰
        _bootstrapped = true;
        return;
      }
      if (fresh.isEmpty) return;

      final freshHits = hits
          .where((h) => fresh.contains('bo|${h.platform}|${h.article.title}'))
          .toList();
      ref.read(notificationServiceProvider).showSignalAlert(
            title: '破圈信号 ${freshHits.length} 条',
            body: freshHits
                .take(_maxPerNotify)
                .map((h) => '${h.platform}：${_short(h.article.title)}（${h.keyword}）')
                .join('  '),
            payload: freshHits.first.article.url,
          );
    } catch (_) {
      // 告警轮询失败静默：下一轮继续
    }
  }

  String _short(String title) =>
      title.length > 30 ? '${title.substring(0, 30)}…' : title;
}
