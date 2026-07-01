import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  test('Article 默认 tickers 为空列表', () {
    final a = _buildArticle();
    expect(a.tickers, isEmpty);
  });

  test('copyWith 携带 tickers', () {
    final a = _buildArticle();
    final ref = TickerRef(
      symbol: 'ETH',
      asset: AssetClass.crypto,
      mentions: 2,
      inTitle: true,
    );
    final b = a.copyWith(tickers: [ref]);
    expect(b.tickers.single.symbol, 'ETH');
  });

  test('toJson/fromJson 往返保持 tickers，旧数据缺失时回退空', () {
    final a = _buildArticle().copyWith(
      tickers: [
        TickerRef(symbol: 'BTC', asset: AssetClass.crypto, mentions: 1, inTitle: false),
      ],
    );
    final json = a.toJson();
    expect((json['tickers'] as List).length, 1);

    // 旧数据无 tickers 字段
    final legacy = Map<String, dynamic>.from(json)..remove('tickers');
    final b = Article.fromJson(legacy);
    expect(b.tickers, isEmpty);
  });
}

Article _buildArticle() => Article(
      id: 'a1',
      feedId: 'f1',
      feedName: '测试源',
      title: 'ETH 上海升级临近',
      url: 'https://example.com/a1',
    );
