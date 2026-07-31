// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 搜索历史 store：持久化最近 10 条搜索词。

@ProviderFor(SearchHistory)
final searchHistoryProvider = SearchHistoryProvider._();

/// 搜索历史 store：持久化最近 10 条搜索词。
final class SearchHistoryProvider
    extends $NotifierProvider<SearchHistory, List<String>> {
  /// 搜索历史 store：持久化最近 10 条搜索词。
  SearchHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryHash();

  @$internal
  @override
  SearchHistory create() => SearchHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$searchHistoryHash() => r'61d791e45c151526c676a23cd9dab96bcb3229b2';

/// 搜索历史 store：持久化最近 10 条搜索词。

abstract class _$SearchHistory extends $Notifier<List<String>> {
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

/// 搜索控制器：对 [articleCacheProvider] 做本地过滤，命中标题优先排序。

@ProviderFor(SearchController)
final searchControllerProvider = SearchControllerProvider._();

/// 搜索控制器：对 [articleCacheProvider] 做本地过滤，命中标题优先排序。
final class SearchControllerProvider
    extends $NotifierProvider<SearchController, SearchState> {
  /// 搜索控制器：对 [articleCacheProvider] 做本地过滤，命中标题优先排序。
  SearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchControllerHash();

  @$internal
  @override
  SearchController create() => SearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchState>(value),
    );
  }
}

String _$searchControllerHash() => r'641cebbff308488cf139ea2cccdcc7195dee22a9';

/// 搜索控制器：对 [articleCacheProvider] 做本地过滤，命中标题优先排序。

abstract class _$SearchController extends $Notifier<SearchState> {
  SearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchState, SearchState>,
              SearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
