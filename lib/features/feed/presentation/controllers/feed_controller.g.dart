// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeedController)
final feedControllerProvider = FeedControllerFamily._();

final class FeedControllerProvider
    extends $AsyncNotifierProvider<FeedController, List<Article>> {
  FeedControllerProvider._({
    required FeedControllerFamily super.from,
    required FeedType super.argument,
  }) : super(
         retry: null,
         name: r'feedControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedControllerHash();

  @override
  String toString() {
    return r'feedControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FeedController create() => FeedController();

  @override
  bool operator ==(Object other) {
    return other is FeedControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedControllerHash() => r'c9b9db87e0e436097f0ad87960ebea06c5d3ec5e';

final class FeedControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FeedController,
          AsyncValue<List<Article>>,
          List<Article>,
          FutureOr<List<Article>>,
          FeedType
        > {
  FeedControllerFamily._()
    : super(
        retry: null,
        name: r'feedControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedControllerProvider call(FeedType feedType) =>
      FeedControllerProvider._(argument: feedType, from: this);

  @override
  String toString() => r'feedControllerProvider';
}

abstract class _$FeedController extends $AsyncNotifier<List<Article>> {
  late final _$args = ref.$arg as FeedType;
  FeedType get feedType => _$args;

  FutureOr<List<Article>> build(FeedType feedType);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Article>>, List<Article>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Article>>, List<Article>>,
              AsyncValue<List<Article>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
