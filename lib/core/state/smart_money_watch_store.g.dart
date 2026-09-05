// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_money_watch_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聪明钱关注列表：用户关注的大户 handle（上游区分大小写，原样存储）。
///
/// 聪明钱页一键关注/取关，后台告警轮询据此决定是否推送该大户的成交；
/// 持久化到 SharedPreferences，与 [CryptoWatchlistStore] 同一套模式。

@ProviderFor(SmartMoneyWatchStore)
final smartMoneyWatchStoreProvider = SmartMoneyWatchStoreProvider._();

/// 聪明钱关注列表：用户关注的大户 handle（上游区分大小写，原样存储）。
///
/// 聪明钱页一键关注/取关，后台告警轮询据此决定是否推送该大户的成交；
/// 持久化到 SharedPreferences，与 [CryptoWatchlistStore] 同一套模式。
final class SmartMoneyWatchStoreProvider
    extends $NotifierProvider<SmartMoneyWatchStore, List<String>> {
  /// 聪明钱关注列表：用户关注的大户 handle（上游区分大小写，原样存储）。
  ///
  /// 聪明钱页一键关注/取关，后台告警轮询据此决定是否推送该大户的成交；
  /// 持久化到 SharedPreferences，与 [CryptoWatchlistStore] 同一套模式。
  SmartMoneyWatchStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartMoneyWatchStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartMoneyWatchStoreHash();

  @$internal
  @override
  SmartMoneyWatchStore create() => SmartMoneyWatchStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$smartMoneyWatchStoreHash() =>
    r'f77d47977e6681c3e1a0d6ab7ae1bba5dcd7c9ea';

/// 聪明钱关注列表：用户关注的大户 handle（上游区分大小写，原样存储）。
///
/// 聪明钱页一键关注/取关，后台告警轮询据此决定是否推送该大户的成交；
/// 持久化到 SharedPreferences，与 [CryptoWatchlistStore] 同一套模式。

abstract class _$SmartMoneyWatchStore extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
