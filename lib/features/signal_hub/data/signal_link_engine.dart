import '../../crypto_radar/data/models/trade_signal.dart';
import '../domain/entities/linkable_article.dart';
import '../domain/entities/signal_link.dart';
import '../domain/entities/ticker_ref.dart';

/// Signal Link 关联引擎：在时间窗内把「事件（RSS 文章）」与「异动（雷达信号）」
/// 配对，输出 0–100 可解释的关联强度。
///
/// 公式（与设计文档一致）：
///   关联强度 = 时间邻近度(40%) × 标的匹配度(30%) × 异动剧烈度(30%)
///
/// 纯逻辑、无 I/O、无 Flutter 依赖，便于单元测试与在 provider 中同步计算。
class SignalLinkEngine {
  /// 时间窗：事件与异动超过 [timeWindow] 分钟视为无关联。
  final int timeWindowMinutes;

  const SignalLinkEngine({this.timeWindowMinutes = 120});

  /// 对全部「文章 × 信号」组合配对，按关联强度降序返回。
  ///
  /// [now] 为当前时间，用于计算时间邻近度（雷达信号视为即时发生）。
  /// 每篇文章对同一信号最多保留一条配对（取命中 ticker 的最佳匹配）。
  List<SignalLink> link({
    required List<LinkableArticle> articles,
    required List<TradeSignal> signals,
    required DateTime now,
  }) {
    final links = <SignalLink>[];

    for (final signal in signals) {
      for (final article in articles) {
        final link = _pair(signal, article, now);
        if (link != null) links.add(link);
      }
    }

    links.sort((a, b) => b.strength.compareTo(a.strength));
    return links;
  }

  /// 配对单个信号与单篇文章；无有效关联（时间超窗且无标的命中）时返回 null。
  SignalLink? _pair(TradeSignal signal, LinkableArticle article, DateTime now) {
    final published = article.publishedAt;
    if (published == null) return null;

    // 1. 时间邻近度：±2h 内线性衰减，超出记 0
    final diffMinutes =
        now.difference(published).inMinutes.abs().toDouble();
    final timeScore = diffMinutes <= timeWindowMinutes
        ? (1 - diffMinutes / timeWindowMinutes).clamp(0.0, 1.0)
        : 0.0;

    // 2. 标的匹配度：遍历文章 ticker，取与信号 coin 的最佳匹配
    final tickers = article.tickers;
    var bestMatch = 0.0;
    var bestSymbol = '';
    for (final t in tickers) {
      final m = _matchScore(t, signal.coin);
      if (m > bestMatch) {
        bestMatch = m;
        bestSymbol = t.symbol;
      }
    }

    // 3. 异动剧烈度：信号 score（0–100）归一化
    final intensityScore = (signal.score / 100).clamp(0.0, 1.0);

    // 时间超窗或无标的命中 → 不产生关联（设计文档：±2h 有效、需标的匹配）
    if (timeScore <= 0 || bestMatch <= 0) return null;

    final strength = ((0.4 * timeScore + 0.3 * bestMatch + 0.3 * intensityScore) * 100)
        .round()
        .clamp(0, 100);

    return SignalLink(
      articleId: article.id,
      articleTitle: article.title,
      signalCoin: signal.coin,
      direction: signal.direction,
      signalScore: signal.score,
      strategy: signal.strategy,
      tickerSymbol: bestSymbol.isEmpty ? signal.coin : bestSymbol,
      strength: strength,
      timeScore: timeScore,
      matchScore: bestMatch,
      intensityScore: intensityScore,
    );
  }

  /// 标的匹配度：精确符号命中 1.0；同为加密（不同币）记 0.5（同板块）。
  double _matchScore(TickerRef ticker, String signalCoin) {
    if (ticker.symbol.toUpperCase() == signalCoin.toUpperCase()) return 1.0;
    if (ticker.asset == AssetClass.crypto) return 0.5;
    return 0.0;
  }
}
