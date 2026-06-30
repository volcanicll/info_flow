import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/feed/presentation/controllers/feed_controller.dart';

part 'article_cache.g.dart';

/// 全局文章缓存：聚合各 feedType 已加载的文章，按 id 索引。
///
/// Reader 页通过 articleId 从此处取真实文章；
/// Search 页从此处做全文搜索。
/// 监听三个 feedType provider，任一刷新自动更新缓存。
@Riverpod(keepAlive: true)
class ArticleCache extends _$ArticleCache {
  @override
  Map<String, Article> build() {
    // 聚合所有 feedType 的当前文章
    final map = <String, Article>{};
    for (final type in FeedType.values) {
      final asyncArticles = ref.watch(feedControllerProvider(type));
      final articles = asyncArticles.valueOrNull ?? [];
      for (final a in articles) {
        map[a.id] = a;
      }
    }
    return map;
  }

  /// 按 id 取文章
  Article? getById(String id) => state[id];

  /// 当前缓存全部文章（供搜索用）
  List<Article> get all => state.values.toList();
}
