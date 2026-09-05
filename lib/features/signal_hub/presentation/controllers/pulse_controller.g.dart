// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pulse_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 脉搏控制器：装配时间线状态。
///
/// watch [articleCacheProvider] 取全部文章 → 用 [TickerResolver] 注入 tickers
/// → 按发布时间倒序 → 与 [tickerQuotesProvider] 的异步结果合并。

@ProviderFor(PulseController)
final pulseControllerProvider = PulseControllerProvider._();

/// 脉搏控制器：装配时间线状态。
///
/// watch [articleCacheProvider] 取全部文章 → 用 [TickerResolver] 注入 tickers
/// → 按发布时间倒序 → 与 [tickerQuotesProvider] 的异步结果合并。
final class PulseControllerProvider
    extends $NotifierProvider<PulseController, PulseState> {
  /// 脉搏控制器：装配时间线状态。
  ///
  /// watch [articleCacheProvider] 取全部文章 → 用 [TickerResolver] 注入 tickers
  /// → 按发布时间倒序 → 与 [tickerQuotesProvider] 的异步结果合并。
  PulseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pulseControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pulseControllerHash();

  @$internal
  @override
  PulseController create() => PulseController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PulseState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PulseState>(value),
    );
  }
}

String _$pulseControllerHash() => r'78ab6f6785c60b291624a04c2f7435da436199f7';

/// 脉搏控制器：装配时间线状态。
///
/// watch [articleCacheProvider] 取全部文章 → 用 [TickerResolver] 注入 tickers
/// → 按发布时间倒序 → 与 [tickerQuotesProvider] 的异步结果合并。

abstract class _$PulseController extends $Notifier<PulseState> {
  PulseState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PulseState, PulseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PulseState, PulseState>,
              PulseState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
