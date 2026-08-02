// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fear_greed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 恐惧贪婪指数：异步拉取，失败返回 null（UI 自行隐藏）。

@ProviderFor(fearGreedIndex)
final fearGreedIndexProvider = FearGreedIndexProvider._();

/// 恐惧贪婪指数：异步拉取，失败返回 null（UI 自行隐藏）。

final class FearGreedIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<FearGreedIndex?>,
          FearGreedIndex?,
          FutureOr<FearGreedIndex?>
        >
    with $FutureModifier<FearGreedIndex?>, $FutureProvider<FearGreedIndex?> {
  /// 恐惧贪婪指数：异步拉取，失败返回 null（UI 自行隐藏）。
  FearGreedIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fearGreedIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fearGreedIndexHash();

  @$internal
  @override
  $FutureProviderElement<FearGreedIndex?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FearGreedIndex?> create(Ref ref) {
    return fearGreedIndex(ref);
  }
}

String _$fearGreedIndexHash() => r'565848f011163f87a4b8b0fa142cdc63f2d8d646';
