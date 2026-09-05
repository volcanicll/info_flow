import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/article_cache.dart';
import '../../../crypto_radar/presentation/controllers/crypto_radar_controller.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../data/ticker_repository.dart';
import '../../data/ticker_resolver.dart';
import '../../data/signal_link_engine.dart';
import '../../domain/entities/linkable_article.dart';
import '../../domain/entities/signal_link.dart';

part 'pulse_controller.g.dart';

/// 脉搏时间线状态：按发布时间倒序的文章 + 当前行情快照 + 信号关联。
class PulseState {
  /// 按发布时间倒序排列的文章（已注入 tickers）
  final List<Article> articles;

  /// symbol -> TickerQuote；用 dynamic 避免 await（同步 build）
  final Map<String, dynamic> quotes;

  /// 文章 ↔ 雷达信号 关联配对（按强度降序）
  final List<SignalLink> links;

  /// 雷达信号 coin 列表（去重、保持出现顺序），用于异动卡区块
  final List<String> radarCoins;

  const PulseState({
    required this.articles,
    required this.quotes,
    this.links = const [],
    this.radarCoins = const [],
  });

  static const empty = PulseState(articles: [], quotes: {});

  /// 指定文章命中的关联（强度 ≥ 阈值），用于文章卡下的关联条。
  List<SignalLink> linksFor(String articleId, {int minStrength = 0}) {
    return links
        .where((l) => l.articleId == articleId && l.strength >= minStrength)
        .toList();
  }

  /// 指定信号 coin 的反向关联新闻（带叙事），用于异动卡。
  List<SignalLink> narrativeFor(String coin, {int minStrength = 0}) {
    return links
        .where((l) => l.signalCoin.toUpperCase() == coin.toUpperCase() &&
            l.strength >= minStrength)
        .toList();
  }

  /// 是否已有雷达信号可供展示（异动卡区块开关）。
  bool get hasRadarSignals => radarCoins.isNotEmpty;
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
    final dict = ref.watch(tickerDictionaryProvider);
    final resolver = TickerResolver(dict);
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
    final q = quotesAsync.value;
    if (q != null) quotes.addAll(q);

    // Signal Link：雷达信号 ↔ 资讯事件 配对（复用引擎，纯计算）
    final radar = ref.watch(cryptoRadarProvider);
    final signals = [
      ...radar.chaseSignals,
      ...radar.combinedSignals,
      ...radar.ambushSignals,
    ];
    final radarCoins = <String>[];
    for (final s in signals) {
      if (!radarCoins.contains(s.coin)) radarCoins.add(s.coin);
    }
    final links = signals.isEmpty
        ? const <SignalLink>[]
        : const SignalLinkEngine().link(
            articles: [
              for (final a in enriched)
                LinkableArticle(
                  id: a.id,
                  title: a.title,
                  publishedAt: a.publishedAt,
                  tickers: a.tickers,
                ),
            ],
            signals: signals,
            now: DateTime.now(),
          );

    return PulseState(
      articles: enriched,
      quotes: quotes,
      links: links,
      radarCoins: radarCoins,
    );
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
