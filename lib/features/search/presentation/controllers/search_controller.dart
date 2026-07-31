import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/article_cache.dart';
import '../../../../core/storage/kv_storage.dart';
import '../../../feed/domain/entities/article.dart';

part 'search_controller.g.dart';

/// 搜索范围过滤。
enum SearchFilter { all, article, source, tag }

extension SearchFilterLabel on SearchFilter {
  String get label => switch (this) {
        SearchFilter.all => '全部',
        SearchFilter.article => '文章',
        SearchFilter.source => '来源',
        SearchFilter.tag => '标签',
      };
}

/// 搜索历史 store：持久化最近 10 条搜索词。
@Riverpod(keepAlive: true)
class SearchHistory extends _$SearchHistory {
  static const _key = 'search_history';

  @override
  List<String> build() =>
      ref.read(sharedPreferencesProvider).getStringList(_key) ?? [];

  Future<void> add(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    final next = [kw, ...state.where((h) => h != kw)].take(10).toList();
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }

  Future<void> clear() async {
    state = [];
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

/// 搜索视图状态：关键词、范围、是否已搜索、结果。
class SearchState {
  final String query;
  final SearchFilter filter;
  final bool hasSearched;
  final List<Article> results;

  const SearchState({
    this.query = '',
    this.filter = SearchFilter.all,
    this.hasSearched = false,
    this.results = const [],
  });

  SearchState copyWith({
    String? query,
    SearchFilter? filter,
    bool? hasSearched,
    List<Article>? results,
  }) {
    return SearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      hasSearched: hasSearched ?? this.hasSearched,
      results: results ?? this.results,
    );
  }
}

/// 搜索控制器：对 [articleCacheProvider] 做本地过滤，命中标题优先排序。
@riverpod
class SearchController extends _$SearchController {
  @override
  SearchState build() => const SearchState();

  /// 切换过滤范围，若已有关键词则立即重算。
  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);
    if (state.query.trim().isNotEmpty) {
      query(state.query);
    }
  }

  /// 实时过滤（不写历史）。空串则回到建议态。
  void query(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(query: '', hasSearched: false, results: []);
      return;
    }
    state = state.copyWith(
      query: text,
      hasSearched: true,
      results: _runFilter(trimmed),
    );
  }

  /// 提交搜索：过滤 + 写入历史。
  Future<void> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    query(trimmed);
    await ref.read(searchHistoryProvider.notifier).add(trimmed);
  }

  /// 清空当前查询，回到建议态。
  void clear() => state = const SearchState();

  List<Article> _runFilter(String text) {
    final cache = ref.read(articleCacheProvider);
    final lower = text.toLowerCase();
    bool matchTitle(Article a) =>
        a.title.toLowerCase().contains(lower) ||
        (a.summary?.toLowerCase().contains(lower) ?? false);
    bool matchSource(Article a) => a.feedName.toLowerCase().contains(lower);
    bool matchTag(Article a) =>
        (a.sentiment?.toLowerCase().contains(lower) ?? false) ||
        a.feedName.toLowerCase().contains(lower);

    final results = cache.values.where((a) {
      return switch (state.filter) {
        SearchFilter.article => matchTitle(a),
        SearchFilter.source => matchSource(a),
        SearchFilter.tag => matchTag(a),
        SearchFilter.all => matchTitle(a) || matchSource(a) || matchTag(a),
      };
    }).toList();

    // 命中标题的排在前面，保证相关度靠前。
    results.sort((a, b) {
      final at = a.title.toLowerCase().contains(lower) ? 0 : 1;
      final bt = b.title.toLowerCase().contains(lower) ? 0 : 1;
      return at.compareTo(bt);
    });
    return results;
  }
}
