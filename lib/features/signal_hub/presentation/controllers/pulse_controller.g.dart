// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pulse_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pulseControllerHash() => r'2a9787f88b253bc68967fc0e88abdc3b034a26ad';

/// 脉搏控制器：装配时间线状态。
///
/// watch [articleCacheProvider] 取全部文章 → 用 [TickerResolver] 注入 tickers
/// → 按发布时间倒序 → 与 [tickerQuotesProvider] 的异步结果合并。
///
/// Copied from [PulseController].
@ProviderFor(PulseController)
final pulseControllerProvider =
    AutoDisposeNotifierProvider<PulseController, PulseState>.internal(
      PulseController.new,
      name: r'pulseControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pulseControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PulseController = AutoDisposeNotifier<PulseState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
