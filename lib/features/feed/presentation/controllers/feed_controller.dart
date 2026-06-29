import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/rss_repository.dart';
import '../../data/rss_sources.dart';
import '../../domain/entities/article.dart';

part 'feed_controller.g.dart';

enum FeedType { recommend, following, hot }

/// 信息流控制器
///
/// 数据来自真实 RSS 源（见 [RssSources]）：
/// - recommend：全部默认订阅源，按时间倒序
/// - following：精选关注的源
/// - hot：按发布时间近 + 来源热度排序
@riverpod
class FeedController extends _$FeedController {
  List<Article> _all = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 12;

  @override
  FutureOr<List<Article>> build(FeedType feedType) {
    _all = [];
    _hasMore = true;
    _isLoadingMore = false;
    return _loadArticles();
  }

  Future<List<Article>> _loadArticles() async {
    final repo = ref.read(rssRepositoryProvider);
    final sources = _sourcesForType(feedType);
    final articles = await repo.fetchSources(sources);
    _all = articles;
    if (articles.length <= _pageSize) _hasMore = false;
    return _paginate(articles, 1);
  }

  List<RssSource> _sourcesForType(FeedType type) {
    switch (type) {
      case FeedType.recommend:
        return RssSources.all;
      case FeedType.following:
        return RssSources.defaultSubscribedIds
            .map(RssSources.byId)
            .whereType<RssSource>()
            .toList();
      case FeedType.hot:
        // 热榜：聚焦活跃社区与媒体
        return [
          RssSources.byId('hackernews'),
          RssSources.byId('36kr'),
          RssSources.byId('techcrunch'),
          RssSources.byId('verge'),
          RssSources.byId('github'),
          RssSources.byId('solidot'),
        ].whereType<RssSource>().toList();
    }
  }

  List<Article> _paginate(List<Article> all, int page) {
    final start = (page - 1) * _pageSize;
    if (start >= all.length) return [];
    final end = start + _pageSize;
    return all.sublist(start, end.clamp(0, all.length));
  }

  Future<void> refresh() async {
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadArticles());
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.valueOrNull ?? [];
    if (current.length >= _all.length) {
      _hasMore = false;
      return;
    }
    _isLoadingMore = true;
    final nextPage = (current.length ~/ _pageSize) + 1;
    final more = _paginate(_all, nextPage);
    state = AsyncData([...current, ...more]);
    _isLoadingMore = false;
  }

  Future<void> toggleLike(String articleId) async {
    final articles = state.valueOrNull ?? [];
    final index = articles.indexWhere((a) => a.id == articleId);
    if (index == -1) return;

    final article = articles[index];
    final updated = article.copyWith(isLiked: !article.isLiked);
    articles[index] = updated;
    state = AsyncData(List.from(articles));
  }

  Future<void> toggleBookmark(String articleId) async {
    final articles = state.valueOrNull ?? [];
    final index = articles.indexWhere((a) => a.id == articleId);
    if (index == -1) return;

    final article = articles[index];
    final updated = article.copyWith(isBookmarked: !article.isBookmarked);
    articles[index] = updated;
    state = AsyncData(List.from(articles));
  }
}
