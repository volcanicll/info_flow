// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$articleCacheHash() => r'7993d3e6fd16003ce170c49ca91b465cfa2a82f9';

/// 全局文章缓存：聚合各 feedType 已加载的文章，按 id 索引。
///
/// Reader 页通过 articleId 从此处取真实文章；
/// Search 页从此处做全文搜索。
/// 监听三个 feedType provider，任一刷新自动更新缓存。
///
/// Copied from [ArticleCache].
@ProviderFor(ArticleCache)
final articleCacheProvider =
    NotifierProvider<ArticleCache, Map<String, Article>>.internal(
      ArticleCache.new,
      name: r'articleCacheProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$articleCacheHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ArticleCache = Notifier<Map<String, Article>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
