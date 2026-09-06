// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crypto_watchlist_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 加密自选列表：用户关注的币种（大写简称，如 BTC / SOL）。
///
/// 用 List 保持用户添加顺序（UI 按此顺序渲染），全部持久化到
/// SharedPreferences。所有页面 watch 此 provider，任一处加星/去星
/// 自动通知全部 watcher，实现雷达页、脉搏页、详情页联动。

@ProviderFor(CryptoWatchlistStore)
final cryptoWatchlistStoreProvider = CryptoWatchlistStoreProvider._();

/// 加密自选列表：用户关注的币种（大写简称，如 BTC / SOL）。
///
/// 用 List 保持用户添加顺序（UI 按此顺序渲染），全部持久化到
/// SharedPreferences。所有页面 watch 此 provider，任一处加星/去星
/// 自动通知全部 watcher，实现雷达页、脉搏页、详情页联动。
final class CryptoWatchlistStoreProvider
    extends $NotifierProvider<CryptoWatchlistStore, List<String>> {
  /// 加密自选列表：用户关注的币种（大写简称，如 BTC / SOL）。
  ///
  /// 用 List 保持用户添加顺序（UI 按此顺序渲染），全部持久化到
  /// SharedPreferences。所有页面 watch 此 provider，任一处加星/去星
  /// 自动通知全部 watcher，实现雷达页、脉搏页、详情页联动。
  CryptoWatchlistStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cryptoWatchlistStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cryptoWatchlistStoreHash();

  @$internal
  @override
  CryptoWatchlistStore create() => CryptoWatchlistStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$cryptoWatchlistStoreHash() =>
    r'1ffe081f8629d4f859957b95b444919f991a39a1';

/// 加密自选列表：用户关注的币种（大写简称，如 BTC / SOL）。
///
/// 用 List 保持用户添加顺序（UI 按此顺序渲染），全部持久化到
/// SharedPreferences。所有页面 watch 此 provider，任一处加星/去星
/// 自动通知全部 watcher，实现雷达页、脉搏页、详情页联动。

abstract class _$CryptoWatchlistStore extends $Notifier<List<String>> {
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
