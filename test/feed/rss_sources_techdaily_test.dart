import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/data/rss_sources.dart';

void main() {
  group('Web3 & 四大链生态订阅源注册表', () {
    test('包含四大链及行业分类', () {
      expect(FeedCategory.values, contains(FeedCategory.solana));
      expect(FeedCategory.values, contains(FeedCategory.base));
      expect(FeedCategory.values, contains(FeedCategory.bsc));
      expect(FeedCategory.values, contains(FeedCategory.robinhood));
      expect(FeedCategory.values, contains(FeedCategory.news));
      expect(FeedCategory.values, contains(FeedCategory.defi));
    });

    test('四大链专属生态源存在且分类正确', () {
      final sol = RssSources.byId('solana-floor');
      final base = RssSources.byId('base-mirror');
      final bsc = RssSources.byId('bsc-news');
      final rh = RssSources.byId('robinhood-crypto');

      expect(sol, isNotNull);
      expect(sol!.category, FeedCategory.solana);

      expect(base, isNotNull);
      expect(base!.category, FeedCategory.base);

      expect(bsc, isNotNull);
      expect(bsc!.category, FeedCategory.bsc);

      expect(rh, isNotNull);
      expect(rh!.category, FeedCategory.robinhood);
    });

    test('行业顶级新闻源与投研源已注册', () {
      for (final id in ['coindesk', 'decrypt', 'blockworks', 'foresight-news', 'bankless']) {
        expect(RssSources.byId(id), isNotNull, reason: '$id 应已注册');
      }
    });

    test('所有注册源 id 唯一', () {
      final ids = RssSources.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('默认订阅包含四大链重点源', () {
      expect(RssSources.defaultSubscribedIds, contains('solana-floor'));
      expect(RssSources.defaultSubscribedIds, contains('base-mirror'));
      expect(RssSources.defaultSubscribedIds, contains('bsc-news'));
      expect(RssSources.defaultSubscribedIds, contains('robinhood-crypto'));
    });
  });
}
