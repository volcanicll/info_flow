// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breakout_alerts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 破圈后台告警：10 分钟轮询一次微博/知乎/头条热榜，命中 Web3
/// 关键词且未推送过即本地推送。
///
/// 大众热榜更新节奏为分钟级，且 NewsNow 服务端缓存约 30 分钟，
/// 轮询间隔取 10 分钟足够。首轮只建立指纹基线不告警（避免启动时
/// 把既有热榜当成新信号轰炸）；受「强信号推送」总开关约束。

@ProviderFor(BreakoutAlerts)
final breakoutAlertsProvider = BreakoutAlertsProvider._();

/// 破圈后台告警：10 分钟轮询一次微博/知乎/头条热榜，命中 Web3
/// 关键词且未推送过即本地推送。
///
/// 大众热榜更新节奏为分钟级，且 NewsNow 服务端缓存约 30 分钟，
/// 轮询间隔取 10 分钟足够。首轮只建立指纹基线不告警（避免启动时
/// 把既有热榜当成新信号轰炸）；受「强信号推送」总开关约束。
final class BreakoutAlertsProvider
    extends $NotifierProvider<BreakoutAlerts, void> {
  /// 破圈后台告警：10 分钟轮询一次微博/知乎/头条热榜，命中 Web3
  /// 关键词且未推送过即本地推送。
  ///
  /// 大众热榜更新节奏为分钟级，且 NewsNow 服务端缓存约 30 分钟，
  /// 轮询间隔取 10 分钟足够。首轮只建立指纹基线不告警（避免启动时
  /// 把既有热榜当成新信号轰炸）；受「强信号推送」总开关约束。
  BreakoutAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'breakoutAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$breakoutAlertsHash();

  @$internal
  @override
  BreakoutAlerts create() => BreakoutAlerts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$breakoutAlertsHash() => r'c66122751d721f9ab9107b27bce0cf6dbd8ac794';

/// 破圈后台告警：10 分钟轮询一次微博/知乎/头条热榜，命中 Web3
/// 关键词且未推送过即本地推送。
///
/// 大众热榜更新节奏为分钟级，且 NewsNow 服务端缓存约 30 分钟，
/// 轮询间隔取 10 分钟足够。首轮只建立指纹基线不告警（避免启动时
/// 把既有热榜当成新信号轰炸）；受「强信号推送」总开关约束。

abstract class _$BreakoutAlerts extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
