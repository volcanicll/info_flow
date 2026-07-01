import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/article_cache.dart';
import '../../../feed/domain/entities/article.dart';
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

    // 按发布时间倒序；缺失时间的文章退回 2000 年避免 null 比较
    enriched.sort((a, b) {
      final ta = a.publishedAt ?? DateTime(2000);
      final tb = b.publishedAt ?? DateTime(2000);
      return tb.compareTo(ta);
    });

    // quotes 异步：同步 build 取 valueOrNull，AsyncValue 完成后自动刷新
    final quotesAsync = ref.watch(tickerQuotesProvider);
    final quotes = <String, dynamic>{};
    final q = quotesAsync.valueOrNull;
    if (q != null) quotes.addAll(q);

    return PulseState(articles: enriched, quotes: quotes);
  }
}
