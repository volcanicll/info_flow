import 'package:flutter_test/flutter_test.dart';

import 'package:info_flow/features/crypto_radar/data/models/trade_signal.dart';
import 'package:info_flow/features/signal_hub/data/signal_link_engine.dart';
import 'package:info_flow/features/signal_hub/domain/entities/linkable_article.dart';
import 'package:info_flow/features/signal_hub/domain/entities/signal_link.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

TradeSignal _signal({
  String coin = 'ETH',
  String direction = 'long',
  int score = 80,
}) {
  return TradeSignal(
    coin: coin,
    sym: '${coin}USDT',
    direction: direction,
    score: score,
    strategy: 'chase',
    price: 1800,
    entry: 1750,
    sl: 1700,
    tp: 2000,
    slPct: 0.05,
    margin: 100,
    notional: 5000,
    risk: 1.0,
    tags: const ['OI'],
    urgency: 'mid',
  );
}

LinkableArticle _article({
  String id = 'a1',
  String title = '以太坊升级带动生态热度',
  DateTime? publishedAt,
  List<TickerRef> tickers = const [
    TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 3, inTitle: true),
  ],
}) {
  return LinkableArticle(
    id: id,
    title: title,
    publishedAt: publishedAt,
    tickers: tickers,
  );
}

void main() {
  const engine = SignalLinkEngine();

  group('SignalLinkEngine', () {
    test('时间窗内精确标的目标 → 产生关联，强度与三因子正相关', () {
      final now = DateTime(2026, 7, 2, 12, 0);
      final links = engine.link(
        articles: [
          _article(publishedAt: now.subtract(const Duration(minutes: 30))),
        ],
        signals: [_signal()],
        now: now,
      );
      expect(links, hasLength(1));
      final l = links.first;
      // strength = (0.4×0.75 + 0.3×1.0 + 0.3×0.8) × 100 = 84
      expect(l.strength, 84);
    });

    test('超过 2h 时间窗 → 不产生关联', () {
      final now = DateTime(2026, 7, 2, 12, 0);
      final links = engine.link(
        articles: [
          _article(publishedAt: now.subtract(const Duration(hours: 3))),
        ],
        signals: [_signal()],
        now: now,
      );
      expect(links, isEmpty);
    });

    test('无标的目标文章不关联（即使时间窗内）', () {
      final now = DateTime(2026, 7, 2, 12, 0);
      final links = engine.link(
        articles: [
          _article(
            publishedAt: now.subtract(const Duration(minutes: 10)),
            tickers: const [
              TickerRef(symbol: 'GOLD', asset: AssetClass.metal, mentions: 1, inTitle: false),
            ],
          ),
        ],
        signals: [_signal()],
        now: now,
      );
      expect(links, isEmpty);
    });

    test('同板块（加密不同币）记 0.5 匹配度', () {
      final now = DateTime(2026, 7, 2, 12, 0);
      final links = engine.link(
        articles: [
          _article(
            publishedAt: now.subtract(const Duration(minutes: 10)),
            tickers: const [
              TickerRef(symbol: 'BTC', asset: AssetClass.crypto, mentions: 2, inTitle: true),
            ],
          ),
        ],
        signals: [_signal(coin: 'ETH')],
        now: now,
      );
      expect(links, hasLength(1));
      expect(links.first.matchScore, 0.5);
    });

    test('按关联强度降序排列', () {
      final now = DateTime(2026, 7, 2, 12, 0);
      final links = engine.link(
        articles: [
          // 更近的文章 → 时间分更高
          _article(
            id: 'new',
            publishedAt: now.subtract(const Duration(minutes: 5)),
          ),
          _article(
            id: 'old',
            publishedAt: now.subtract(const Duration(minutes: 110)),
          ),
        ],
        signals: [_signal()],
        now: now,
      );
      expect(links, hasLength(2));
      expect(links.first.articleId, 'new');
      expect(links.last.articleId, 'old');
    });

    test('无文章或无信号 → 空结果', () {
      final now = DateTime(2026, 7, 2, 12, 0);
      expect(engine.link(articles: [], signals: [_signal()], now: now), isEmpty);
      expect(engine.link(articles: [_article(publishedAt: now)], signals: [], now: now), isEmpty);
    });
  });

  group('SignalLink tier', () {
    SignalLink linkWith(int strength) => SignalLink(
          articleId: 'a',
          articleTitle: 't',
          signalCoin: 'ETH',
          direction: 'long',
          signalScore: 80,
          strategy: 'chase',
          tickerSymbol: 'ETH',
          strength: strength,
          timeScore: 0.5,
          matchScore: 1.0,
          intensityScore: 0.8,
        );

    test('≥85 强信号', () {
      expect(linkWith(85).tier, SignalLinkTier.strong);
      expect(linkWith(92).tier, SignalLinkTier.strong);
    });

    test('70–84 中信号', () {
      expect(linkWith(70).tier, SignalLinkTier.medium);
      expect(linkWith(84).tier, SignalLinkTier.medium);
    });

    test('<70 弱关联', () {
      expect(linkWith(69).tier, SignalLinkTier.weak);
    });
  });
}
