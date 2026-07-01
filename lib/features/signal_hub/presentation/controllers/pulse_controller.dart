import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/article_cache.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../data/ticker_repository.dart';
import '../../data/ticker_resolver.dart';

part 'pulse_controller.g.dart';

/// 脉搏时间线状态：按发布时间倒序的文章 + 当前行情快照。
class PulseState {
  /// 按发布时间倒序排列的文章（已注入 tickers）
  final List<Article> articles;

  /// symbol -> TickerQuote；用 dynamic 避免 await（同步 build）
  final Map<String, dynamic> quotes;

  const PulseState({required this.articles, required this.quotes});

  static const empty = PulseState(articles: [], quotes: {});
}

/// 脉搏控制器：装配时间线状态。
///
/// watch [articleCacheProvider] 取全部文章 → 用 [TickerResolver] 注入 tickers
/// → 按发布时间倒序 → 与 [tickerQuotesProvider] 的异步结果合并。
@riverpod
class PulseController extends _$PulseController {
  @override
  PulseState build() {
    final cache = ref.watch(articleCacheProvider);
    final resolver = TickerResolver();
    final enriched = resolver.resolveList(cache.values.toList());

    // 按发布时间倒序；缺失时间的文章退回 2000 年避免 null 比较。
    // publishedAt 相同（含都为 null）时以 id 做二级排序，保证刷新后顺序稳定（I2）。
    enriched.sort((a, b) {
      final ta = a.publishedAt ?? DateTime(2000);
      final tb = b.publishedAt ?? DateTime(2000);
      final cmp = tb.compareTo(ta);
      return cmp != 0 ? cmp : a.id.compareTo(b.id);
    });

    // quotes 异步：同步 build 取 valueOrNull，AsyncValue 完成后自动刷新
    final quotesAsync = ref.watch(tickerQuotesProvider);
    final quotes = <String, dynamic>{};
    final q = quotesAsync.valueOrNull;
    if (q != null) quotes.addAll(q);

    return PulseState(articles: enriched, quotes: quotes);
  }

  /// 手动刷新：委托三个 FeedController 拉取最新文章。
  ///
  /// [articleCacheProvider] watch 了这三个 feedControllerProvider，刷新它们
  /// 会让 cache 重建，进而触发本 provider 重新 build，脉搏页自动更新。
  Future<void> refresh() async {
    await Future.wait(FeedType.values.map(
      (t) => ref.read(feedControllerProvider(t).notifier).refresh()),
    );
  }
}
