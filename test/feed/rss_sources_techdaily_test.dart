import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/data/rss_sources.dart';

void main() {
  group('TechDaily 集成后的订阅源注册表', () {
    test('新增宏观与社区分类', () {
      expect(FeedCategory.values, contains(FeedCategory.macro));
      expect(FeedCategory.values, contains(FeedCategory.community));
    });

    test('宏观金融源存在且分类正确', () {
      final cnbc = RssSources.byId('cnbc-markets');
      final reuters = RssSources.byId('reuters-business');
      final bloomberg = RssSources.byId('bloomberg-markets');

      expect(cnbc, isNotNull);
      expect(cnbc!.category, FeedCategory.macro);
      expect(cnbc.feedUrl, contains('cnbc.com'));
      expect(reuters, isNotNull);
      expect(reuters!.category, FeedCategory.macro);
      expect(bloomberg, isNotNull);
      expect(bloomberg!.category, FeedCategory.macro);
    });

    test('AI 官方/研究博客源存在', () {
      for (final id in ['mit-tech-ai', 'google-ai', 'openai-news', 'arxiv-cs-ai']) {
        expect(RssSources.byId(id), isNotNull, reason: '$id 应已注册');
      }
      expect(RssSources.byId('openai-news')!.category, FeedCategory.ai);
      expect(RssSources.byId('arxiv-cs-ai')!.feedUrl, contains('arxiv.org'));
    });

    test('社区源（Reddit/掘金/SegmentFault/Lobsters）存在', () {
      for (final id in [
        'lobsters',
        'reddit-programming',
        'reddit-ml',
        'reddit-localllama',
        'juejin',
        'segmentfault',
      ]) {
        final src = RssSources.byId(id);
        expect(src, isNotNull, reason: '$id 应已注册');
        expect(src!.category, FeedCategory.community);
      }
    });

    test('默认订阅包含新增的高价值源', () {
      for (final id in [
        'cnbc-markets',
        'mit-tech-ai',
        'openai-news',
        'github-blog',
        'lobsters',
        'reddit-programming',
        'juejin',
      ]) {
        expect(RssSources.defaultSubscribedIds, contains(id), reason: '$id 应默认订阅');
      }
    });

    test('所有注册源 id 唯一', () {
      final ids = RssSources.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
