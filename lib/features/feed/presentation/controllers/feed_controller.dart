import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../subscription/data/subscription_store.dart';
import 'package:info_flow/features/signal_hub/data/ticker_resolver.dart';
import 'package:info_flow/features/feed/data/newsnow_repository.dart';
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
  List<RssSource> _sourceQueue = [];
  int _sourceCursor = 0;
  Set<String> _seenUrls = {};
  static const int _pageSize = 12;
  static const int _maxPerSource = 10;
  static const int _initialBatchSize = 3;
  static const int _loadMoreBatchSize = 3;
  Set<String>? _subscribedIds;

  bool get hasMore => _hasMore;

  @override
  FutureOr<List<Article>> build(FeedType feedType) {
    _all = [];
    _hasMore = true;
    _isLoadingMore = false;
    _sourceQueue = [];
    _sourceCursor = 0;
    _seenUrls = {};
    _subscribedIds = feedType == FeedType.following
        ? ref.watch(subscriptionStoreProvider)
        : null;
    return _loadArticles();
  }

  Future<List<Article>> _loadArticles() async {
    // 热榜 = NewsNow 实时快讯流（财联社/华尔街见闻/金十/FastBull），
    // 一次性载入，无分页；条目经同一 ticker 词典标注徽章。
    if (feedType == FeedType.hot) {
      final flashes = await ref.read(newsNowRepositoryProvider).fetchFlashes();
      if (flashes.isEmpty) {
        throw Exception('快讯源均加载失败，请检查网络连接');
      }
      _all = TickerResolver().resolveList(flashes);
      _hasMore = false;
      return _paginate(_all, 1);
    }

    final repo = ref.read(rssRepositoryProvider);
    _sourceQueue = _sourcesForType(feedType);
    _sourceCursor = 0;

    if (_sourceQueue.isEmpty) return [];

    await _fetchNextBatch(_initialBatchSize);

    if (_all.isEmpty &&
        _sourceCursor >= _sourceQueue.length &&
        repo.failedCount >= _sourceQueue.length) {
      throw Exception('所有订阅源均加载失败，请检查网络连接');
    }

    if (_all.length <= _pageSize) _hasMore = false;
    return _paginate(_all, 1);
  }

  /// 抓取下一批订阅源，去重、注入 tickers、按时间排序后追加到 _all
  Future<void> _fetchNextBatch(int count) async {
    if (_sourceCursor >= _sourceQueue.length) {
      _hasMore = false;
      return;
    }

    final repo = ref.read(rssRepositoryProvider);
    final end = (_sourceCursor + count).clamp(0, _sourceQueue.length);
    final batch = _sourceQueue.sublist(_sourceCursor, end);
    _sourceCursor = end;

    final results = await Future.wait(
      batch.map((s) => repo.fetchSource(s, maxItems: _maxPerSource)),
    );

    for (final articles in results) {
      for (final a in articles) {
        final key = a.url.isEmpty ? a.title : a.url;
        if (_seenUrls.add(key)) _all.add(a);
      }
    }

    final resolver = TickerResolver();
    _all = resolver.resolveList(_all);

    _all.sort((a, b) {
      final ta = a.publishedAt ?? DateTime(2000);
      final tb = b.publishedAt ?? DateTime(2000);
      return tb.compareTo(ta);
    });
  }

  List<RssSource> _sourcesForType(FeedType type) {
    switch (type) {
      case FeedType.recommend:
        // 推荐流 = 全部内置源 + 用户自定义源
        final store = ref.read(subscriptionStoreProvider.notifier);
        return [
          ...RssSources.all,
          ...store.customSources.map((c) => c.toRssSource()),
        ];
      case FeedType.following:
        final ids = _subscribedIds;
        if (ids == null || ids.isEmpty) {
          return RssSources.defaultSubscribedIds
              .map(RssSources.byId)
              .whereType<RssSource>()
              .toList();
        }
        return ids
            .map(
              (id) => ref
                  .read(subscriptionStoreProvider.notifier)
                  .resolveSource(id),
            )
            .whereType<RssSource>()
            .toList();
      case FeedType.hot:
        // 热榜走 NewsNow 快讯流（见 _loadArticles），不走 RSS 源队列
        return const [];
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
    _sourceCursor = 0;
    _seenUrls = {};
    final currentData = state.value;
    final result = await AsyncValue.guard(() => _loadArticles());
    if (result.hasValue) {
      state = result;
    } else if (currentData != null && state.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    try {
      final current = state.value ?? [];

      if (current.length >= _all.length) {
        if (_sourceCursor >= _sourceQueue.length) {
          _hasMore = false;
          state = AsyncData([...current]);
          return;
        }

        await _fetchNextBatch(_loadMoreBatchSize);

        if (current.length >= _all.length) {
          _hasMore = false;
          state = AsyncData([...current]);
          return;
        }
      }

      final end = (current.length + _pageSize).clamp(0, _all.length);
      final visible = _all.take(end).toList();
      if (visible.length == current.length) {
        _hasMore = false;
        state = AsyncData([...current]);
        return;
      }
      // 直接取重排后的前 N 条，而不是按旧长度偏移切片：
      // 新批次里的最新条目（如 SoPilot 起爆帖）按日期插在 _all
      // 顶部，偏移切片会让它们落在已加载窗口之外永不露面。
      state = AsyncData(visible);
    } finally {
      _isLoadingMore = false;
    }
  }
}
