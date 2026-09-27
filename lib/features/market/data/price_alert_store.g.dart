// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_alert_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 代币价格提醒规则仓库：持久化到 SharedPreferences（JSON 列表）。
///
/// 管理页增删改查与后台告警引擎共用；触发状态同样落盘，
/// 重启后不会把已触发的规则再推一遍。

@ProviderFor(PriceAlertStore)
final priceAlertStoreProvider = PriceAlertStoreProvider._();

/// 代币价格提醒规则仓库：持久化到 SharedPreferences（JSON 列表）。
///
/// 管理页增删改查与后台告警引擎共用；触发状态同样落盘，
/// 重启后不会把已触发的规则再推一遍。
final class PriceAlertStoreProvider
    extends $NotifierProvider<PriceAlertStore, List<PriceAlert>> {
  /// 代币价格提醒规则仓库：持久化到 SharedPreferences（JSON 列表）。
  ///
  /// 管理页增删改查与后台告警引擎共用；触发状态同样落盘，
  /// 重启后不会把已触发的规则再推一遍。
  PriceAlertStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'priceAlertStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$priceAlertStoreHash();

  @$internal
  @override
  PriceAlertStore create() => PriceAlertStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PriceAlert> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PriceAlert>>(value),
    );
  }
}

String _$priceAlertStoreHash() => r'5a14127d5c06da859c47de9873bd22da4f57fdac';

/// 代币价格提醒规则仓库：持久化到 SharedPreferences（JSON 列表）。
///
/// 管理页增删改查与后台告警引擎共用；触发状态同样落盘，
/// 重启后不会把已触发的规则再推一遍。

abstract class _$PriceAlertStore extends $Notifier<List<PriceAlert>> {
  List<PriceAlert> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<PriceAlert>, List<PriceAlert>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PriceAlert>, List<PriceAlert>>,
              List<PriceAlert>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
