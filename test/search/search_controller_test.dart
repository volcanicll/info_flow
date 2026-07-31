import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/state/article_cache.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/search/presentation/controllers/search_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 固定文章缓存：避免真实 FeedController 触发网络。
class _FakeArticleCache extends ArticleCache {
  @override
  Map<String, Article> build() => {
        'a1': const Article(
          id: 'a1',
          feedId: 'f1',
          feedName: '少数派',
          title: '以太坊完成升级',
          url: 'https://example.com/a1',
          summary: '本次升级降低了 gas 费用',
        ),
        'a2': const Article(
          id: 'a2',
          feedId: 'f2',
          feedName: '华尔街见闻',
          title: '美股收盘走高',
          url: 'https://example.com/a2',
        ),
        'a3': const Article(
          id: 'a3',
          feedId: 'f1',
          feedName: '少数派',
          title: '效率工具推荐',
          url: 'https://example.com/a3',
          summary: '提到了以太坊钱包',
        ),
      };
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      articleCacheProvider.overrideWith(_FakeArticleCache.new),
    ]);
    addTearDown(container.dispose);
    // 保持 autoDispose provider 存活
    container.listen(searchControllerProvider, (_, _) {});
  });

  group('SearchController', () {
    test('初始为建议态：未搜索且无结果', () {
      final s = container.read(searchControllerProvider);
      expect(s.hasSearched, false);
      expect(s.results, isEmpty);
    });

    test('query 命中标题与摘要，命中标题者排前', () {
      container.read(searchControllerProvider.notifier).query('以太坊');
      final s = container.read(searchControllerProvider);
      expect(s.hasSearched, true);
      expect(s.results.length, 2);
      // a1 标题命中排前，a3 仅摘要命中排后
      expect(s.results.first.id, 'a1');
      expect(s.results.last.id, 'a3');
    });

    test('空串 query 回到建议态', () {
      final n = container.read(searchControllerProvider.notifier);
      n.query('以太坊');
      n.query('   ');
      final s = container.read(searchControllerProvider);
      expect(s.hasSearched, false);
      expect(s.results, isEmpty);
    });

    test('setFilter(source) 只按来源过滤并立即重算', () {
      final n = container.read(searchControllerProvider.notifier);
      n.query('少数派');
      n.setFilter(SearchFilter.source);
      final s = container.read(searchControllerProvider);
      expect(s.filter, SearchFilter.source);
      expect(s.results.map((a) => a.id), containsAll(['a1', 'a3']));
      expect(s.results.any((a) => a.id == 'a2'), false);
    });

    test('submit 写入搜索历史，去重且新词在前', () async {
      final n = container.read(searchControllerProvider.notifier);
      await n.submit('以太坊');
      await n.submit('美股');
      await n.submit('以太坊');
      expect(container.read(searchHistoryProvider), ['以太坊', '美股']);
    });

    test('clear 复位全部状态', () {
      final n = container.read(searchControllerProvider.notifier);
      n.query('以太坊');
      n.clear();
      final s = container.read(searchControllerProvider);
      expect(s.query, '');
      expect(s.hasSearched, false);
      expect(s.results, isEmpty);
    });
  });
}
