// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_alerts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 代币价格提醒后台引擎：60s 轮询 Binance 现价，命中规则即本地推送。
///
/// 规则来自 [PriceAlertStore]，触发语义一次性（命中即停用，列表里可重新
/// 启用）。规则是显式阈值、基线在创建/重启用时落盘，因此无需首轮建基线，
/// 启动后稍作延迟即可补推停机期间已触发的条件。
/// 受「强信号推送」总开关约束；指纹（含代数）去重兜底持久化写失败的情况。

@ProviderFor(PriceAlerts)
final priceAlertsProvider = PriceAlertsProvider._();

/// 代币价格提醒后台引擎：60s 轮询 Binance 现价，命中规则即本地推送。
///
/// 规则来自 [PriceAlertStore]，触发语义一次性（命中即停用，列表里可重新
/// 启用）。规则是显式阈值、基线在创建/重启用时落盘，因此无需首轮建基线，
/// 启动后稍作延迟即可补推停机期间已触发的条件。
/// 受「强信号推送」总开关约束；指纹（含代数）去重兜底持久化写失败的情况。
final class PriceAlertsProvider extends $NotifierProvider<PriceAlerts, void> {
  /// 代币价格提醒后台引擎：60s 轮询 Binance 现价，命中规则即本地推送。
  ///
  /// 规则来自 [PriceAlertStore]，触发语义一次性（命中即停用，列表里可重新
  /// 启用）。规则是显式阈值、基线在创建/重启用时落盘，因此无需首轮建基线，
  /// 启动后稍作延迟即可补推停机期间已触发的条件。
  /// 受「强信号推送」总开关约束；指纹（含代数）去重兜底持久化写失败的情况。
  PriceAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'priceAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$priceAlertsHash();

  @$internal
  @override
  PriceAlerts create() => PriceAlerts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$priceAlertsHash() => r'e1f9d27ab1e77c7ad2060ab0cbc0fd21ecc03173';

/// 代币价格提醒后台引擎：60s 轮询 Binance 现价，命中规则即本地推送。
///
/// 规则来自 [PriceAlertStore]，触发语义一次性（命中即停用，列表里可重新
/// 启用）。规则是显式阈值、基线在创建/重启用时落盘，因此无需首轮建基线，
/// 启动后稍作延迟即可补推停机期间已触发的条件。
/// 受「强信号推送」总开关约束；指纹（含代数）去重兜底持久化写失败的情况。

abstract class _$PriceAlerts extends $Notifier<void> {
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
