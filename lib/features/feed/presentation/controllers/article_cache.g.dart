// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局文章缓存：聚合各 feedType 已加载的文章，按 id 索引。
///
/// Reader 页通过 articleId 从此处取真实文章；
/// Search 页从此处做全文搜索。
/// 监听三个 feedType provider，任一刷新自动更新缓存。

@ProviderFor(ArticleCache)
final articleCacheProvider = ArticleCacheProvider._();

/// 全局文章缓存：聚合各 feedType 已加载的文章，按 id 索引。
///
/// Reader 页通过 articleId 从此处取真实文章；
/// Search 页从此处做全文搜索。
/// 监听三个 feedType provider，任一刷新自动更新缓存。
final class ArticleCacheProvider
    extends $NotifierProvider<ArticleCache, Map<String, Article>> {
  /// 全局文章缓存：聚合各 feedType 已加载的文章，按 id 索引。
  ///
  /// Reader 页通过 articleId 从此处取真实文章；
  /// Search 页从此处做全文搜索。
  /// 监听三个 feedType provider，任一刷新自动更新缓存。
  ArticleCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleCacheHash();

  @$internal
  @override
  ArticleCache create() => ArticleCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Article> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Article>>(value),
    );
  }
}

String _$articleCacheHash() => r'be58d2f96508831858d38efd952bd7abf400aa42';

/// 全局文章缓存：聚合各 feedType 已加载的文章，按 id 索引。
///
/// Reader 页通过 articleId 从此处取真实文章；
/// Search 页从此处做全文搜索。
/// 监听三个 feedType provider，任一刷新自动更新缓存。

abstract class _$ArticleCache extends $Notifier<Map<String, Article>> {
  Map<String, Article> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, Article>, Map<String, Article>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, Article>, Map<String, Article>>,
              Map<String, Article>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
