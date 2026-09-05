// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_money_alerts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聪明钱后台告警：60s 增量轮询 tape（since_id 游标），命中规则即本地推送。
///
/// 上游站点只提供被动看板，这里是 App 的代差能力：
/// - 关注的大户任何成交 ≥\$500；
/// - 无关注时仅追超大 KOL（粉丝 ≥20 万）的首买，避免打扰。
/// 首轮只建立游标不告警（避免启动时把历史成交当成新信号轰炸）。

@ProviderFor(SmartMoneyAlerts)
final smartMoneyAlertsProvider = SmartMoneyAlertsProvider._();

/// 聪明钱后台告警：60s 增量轮询 tape（since_id 游标），命中规则即本地推送。
///
/// 上游站点只提供被动看板，这里是 App 的代差能力：
/// - 关注的大户任何成交 ≥\$500；
/// - 无关注时仅追超大 KOL（粉丝 ≥20 万）的首买，避免打扰。
/// 首轮只建立游标不告警（避免启动时把历史成交当成新信号轰炸）。
final class SmartMoneyAlertsProvider
    extends $NotifierProvider<SmartMoneyAlerts, void> {
  /// 聪明钱后台告警：60s 增量轮询 tape（since_id 游标），命中规则即本地推送。
  ///
  /// 上游站点只提供被动看板，这里是 App 的代差能力：
  /// - 关注的大户任何成交 ≥\$500；
  /// - 无关注时仅追超大 KOL（粉丝 ≥20 万）的首买，避免打扰。
  /// 首轮只建立游标不告警（避免启动时把历史成交当成新信号轰炸）。
  SmartMoneyAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartMoneyAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartMoneyAlertsHash();

  @$internal
  @override
  SmartMoneyAlerts create() => SmartMoneyAlerts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$smartMoneyAlertsHash() => r'df7d8a42451296f4e0cd60c81e16060631de027a';

/// 聪明钱后台告警：60s 增量轮询 tape（since_id 游标），命中规则即本地推送。
///
/// 上游站点只提供被动看板，这里是 App 的代差能力：
/// - 关注的大户任何成交 ≥\$500；
/// - 无关注时仅追超大 KOL（粉丝 ≥20 万）的首买，避免打扰。
/// 首轮只建立游标不告警（避免启动时把历史成交当成新信号轰炸）。

abstract class _$SmartMoneyAlerts extends $Notifier<void> {
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
