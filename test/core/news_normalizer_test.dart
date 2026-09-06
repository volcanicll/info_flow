import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/models/article.dart';
import 'package:info_flow/core/utils/news_normalizer.dart';

Article _createArticle({required String id, required String title, required String url}) {
  return Article(
    id: id,
    feedId: 'feed-test',
    feedName: 'Test Feed',
    title: title,
    url: url,
  );
}

void main() {
  group('NewsNormalizer.jaccardSimilarity', () {
    test('相同文本相似度为 1.0', () {
      expect(NewsNormalizer.jaccardSimilarity('比特币突破 10 万美元', '比特币突破 10 万美元'), 1.0);
      expect(NewsNormalizer.jaccardSimilarity('Ethereum upgrade is live', 'ethereum upgrade is live'), 1.0);
    });

    test('完全不相关文本相似度为 0.0', () {
      expect(NewsNormalizer.jaccardSimilarity('比特币暴涨', '黄金价格下跌'), 0.0);
    });

    test('空文本返回 0.0', () {
      expect(NewsNormalizer.jaccardSimilarity('', '比特币'), 0.0);
      expect(NewsNormalizer.jaccardSimilarity('', ''), 0.0);
    });

    test('中英文分词与标点清洗计算', () {
      final sim = NewsNormalizer.jaccardSimilarity(
        '【重磅】Solana 现货 ETF 申请提交！',
        'Solana 现货 ETF 申请提交了吗？',
      );
      expect(sim, greaterThan(0.6));
    });
  });

  group('NewsNormalizer.dedupe', () {
    test('空列表返回空列表', () {
      expect(NewsNormalizer.dedupe([]), isEmpty);
    });

    test('URL 相同条目去重', () {
      final a1 = _createArticle(id: '1', title: '标题一', url: 'https://example.com/post/1');
      final a2 = _createArticle(id: '2', title: '标题完全不同', url: 'https://example.com/post/1');
      final result = NewsNormalizer.dedupe([a1, a2]);
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('标题相似度超过阈值判定为重复', () {
      final a1 = _createArticle(id: '1', title: '以太坊现货 ETF 获美 SEC 批准', url: 'https://a.com/1');
      final a2 = _createArticle(id: '2', title: '美 SEC 正式批准以太坊现货 ETF', url: 'https://b.com/2');
      final result = NewsNormalizer.dedupe([a1, a2], threshold: 0.6);
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('标题差异大则全部保留', () {
      final a1 = _createArticle(id: '1', title: '比特币减半完成', url: 'https://a.com/1');
      final a2 = _createArticle(id: '2', title: 'Solana 生态 DEX 交易量创新高', url: 'https://b.com/2');
      final result = NewsNormalizer.dedupe([a1, a2]);
      expect(result.length, 2);
    });
  });
}
