import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/state/subscription_store.dart';
import 'package:info_flow/features/signal_hub/data/ticker_resolver.dart';
import 'package:info_flow/features/feed/data/rss_repository.dart';
import 'package:info_flow/features/feed/data/rss_sources.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';

part 'feed_controller.g.dart';

enum FeedType { recommend, following, hot }

@riverpod
class FeedController extends _$FeedController {
  List<Article> _all = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 12;
  static const int _maxPerSource = 10;
  static const int _batchSize = 3;
  Set<String>? _subscribedIds;

  @override
  FutureOr<List<Article>> build(FeedType feedType) {
    _all = [];
    _hasMore = true;
    _isLoadingMore = false;
    _subscribedIds = feedType == FeedType.following
        ? ref.watch(subscriptionStoreProvider)
        : null;
    return _loadArticles();
  }

  Future<List<Article>> _loadArticles() async {
    final repo = ref.read(rssRepositoryProvider);
    final sources = _sourcesForType(feedType);
    if (sources.isEmpty) return [];

    _all = [];
    final seenUrls = <String>{};

    for (int i = 0; i < sources.length; i += _batchSize) {
      final batch =
          sources.sublist(i, (i + _batchSize).clamp(0, sources.length));
      final results = await Future.wait(
          batch.map((s) => repo.fetchSource(s, maxItems: _maxPerSource)));

      for (final articles in results) {
        for (final a in articles) {
          final key = a.url.isEmpty ? a.title : a.url;
          if (seenUrls.add(key)) _all.add(a);
        }
      }
    }

    // 注入 tickers（已有 tickers 的文章会被跳过），再排序
    final resolver = TickerResolver();
    _all = resolver.resolveList(_all);

    _all.sort((a, b) {
      final ta = a.publishedAt ?? DateTime(2000);
      final tb = b.publishedAt ?? DateTime(2000);
      return tb.compareTo(ta);
    });

    if (_all.isEmpty &&
        sources.isNotEmpty &&
        repo.failedCount == sources.length) {
      throw Exception('所有订阅源均加载失败，请检查网络连接');
    }
    if (_all.length <= _pageSize) _hasMore = false;
    return _paginate(_all, 1);
  }

  List<RssSource> _sourcesForType(FeedType type) {
    switch (type) {
      case FeedType.recommend:
        return RssSources.all;
      case FeedType.following:
        final ids = _subscribedIds;
        if (ids == null || ids.isEmpty) {
          return RssSources.defaultSubscribedIds
              .map(RssSources.byId)
              .whereType<RssSource>()
              .toList();
        }
        return ids
            .map((id) =>
                ref.read(subscriptionStoreProvider.notifier).resolveSource(id))
            .whereType<RssSource>()
            .toList();
      case FeedType.hot:
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
    final currentData = state.valueOrNull;
    final result = await AsyncValue.guard(() => _loadArticles());
    if (result.hasValue) {
      state = result;
    } else if (currentData != null && state.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
    }
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
    final updated =
        article.copyWith(isBookmarked: !article.isBookmarked);
    articles[index] = updated;
    state = AsyncData(List.from(articles));
  }
}
