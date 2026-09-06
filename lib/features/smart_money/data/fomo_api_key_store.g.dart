// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fomo_api_key_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// FOMO API Key（fomoapi.io，免费档 10,000 请求/月）。
///
/// 未配置时：多窗口收益榜仍可用（免 key，IP 限流），
/// 代币聪明钱持仓等按 key 计费的端点对应功能自动隐藏。

@ProviderFor(FomoApiKeyStore)
final fomoApiKeyStoreProvider = FomoApiKeyStoreProvider._();

/// FOMO API Key（fomoapi.io，免费档 10,000 请求/月）。
///
/// 未配置时：多窗口收益榜仍可用（免 key，IP 限流），
/// 代币聪明钱持仓等按 key 计费的端点对应功能自动隐藏。
final class FomoApiKeyStoreProvider
    extends $NotifierProvider<FomoApiKeyStore, String> {
  /// FOMO API Key（fomoapi.io，免费档 10,000 请求/月）。
  ///
  /// 未配置时：多窗口收益榜仍可用（免 key，IP 限流），
  /// 代币聪明钱持仓等按 key 计费的端点对应功能自动隐藏。
  FomoApiKeyStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fomoApiKeyStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fomoApiKeyStoreHash();

  @$internal
  @override
  FomoApiKeyStore create() => FomoApiKeyStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$fomoApiKeyStoreHash() => r'bdeefc29440634ae371ad0ccbacb21ddb1e9850a';

/// FOMO API Key（fomoapi.io，免费档 10,000 请求/月）。
///
/// 未配置时：多窗口收益榜仍可用（免 key，IP 限流），
/// 代币聪明钱持仓等按 key 计费的端点对应功能自动隐藏。

abstract class _$FomoApiKeyStore extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
