import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/state/article_cache.dart';
import '../../../../features/feed/data/rss_sources.dart';
import '../../../feed/domain/entities/article.dart';

/// 搜索页
///
/// 在已抓取的文章池中按 标题/摘要/来源 全文匹配，
/// 搜索历史持久化到 SharedPreferences。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Article> _results = [];
  bool _hasSearched = false;
  List<String> _history = [];
  bool _loading = false;

  static const _kHistory = 'search_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _history = prefs.getStringList(_kHistory) ?? []);
  }

  Future<void> _saveHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final next = [keyword, ..._history.where((h) => h != keyword)].take(10).toList();
    setState(() => _history = next);
    await prefs.setStringList(_kHistory, next);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _history = []);
    await prefs.remove(_kHistory);
  }

  void _doSearch([String? keyword]) {
    final text = (keyword ?? _searchController.text).trim();
    if (text.isEmpty) return;
    _searchController.text = text;
    _saveHistory(text);
    _focusNode.unfocus();

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    // 在文章缓存中搜索
    final cache = ref.read(articleCacheProvider);
    final lower = text.toLowerCase();
    final results = cache.values.where((a) {
      return a.title.toLowerCase().contains(lower) ||
          (a.summary?.toLowerCase().contains(lower) ?? false) ||
          a.feedName.toLowerCase().contains(lower);
    }).toList()
      ..sort((a, b) {
        // 标题命中优先
        final at = a.title.toLowerCase().contains(lower) ? 0 : 1;
        final bt = b.title.toLowerCase().contains(lower) ? 0 : 1;
        return at.compareTo(bt);
      });

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _doSearch,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '搜索文章、来源…',
              hintStyle: theme.textTheme.bodyMedium,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _hasSearched = false;
                          _results = [];
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: _hasSearched
          ? _SearchResults(
              results: _results,
              keyword: _searchController.text.trim(),
              loading: _loading,
            )
          : _SearchSuggestions(
              history: _history,
              onTapHistory: _doSearch,
              onClearHistory: _clearHistory,
            ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTapHistory;
  final VoidCallback onClearHistory;

  const _SearchSuggestions({
    required this.history,
    required this.onTapHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 热门：来自实际订阅源名
    final hotSources = RssSources.all.take(8).map((s) => s.name).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('热门来源', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hotSources.map((s) => ActionChip(
                label: Text(s),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  // 通过 Navigator 取不到 state，用回调走外层搜索
                  // 这里直接触发：把文本写入由外层提供的 onTapHistory
                  onTapHistory(s);
                },
              )).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('搜索历史', style: theme.textTheme.titleSmall),
            if (history.isNotEmpty)
              TextButton.icon(
                onPressed: onClearHistory,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('清空'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('还没有搜索记录',
                style: theme.textTheme.bodySmall),
          )
        else
          ...history.map((h) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, size: 20),
                title: Text(h, style: theme.textTheme.bodyMedium),
                trailing: const Icon(Icons.north_west_rounded,
                    size: 16, color: Colors.grey),
                onTap: () => onTapHistory(h),
              )),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<Article> results;
  final String keyword;
  final bool loading;

  const _SearchResults({
    required this.results,
    required this.keyword,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded,
                    size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text('未找到「$keyword」相关内容',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('换个关键词，或下拉信息流加载更多文章后再试',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final a = results[index];
        return _ResultTile(article: a, keyword: keyword);
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Article article;
  final String keyword;
  const _ResultTile({required this.article, required this.keyword});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/reader/${article.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 来源
            Text(article.feedName, style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            // 标题（高亮关键词）
            _HighlightedText(
              text: article.title,
              keyword: keyword,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
              maxLines: 2,
            ),
            if (article.summary != null) ...[
              const SizedBox(height: 4),
              _HighlightedText(
                text: article.summary!,
                keyword: keyword,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 关键词高亮文本
class _HighlightedText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle? style;
  final int? maxLines;

  const _HighlightedText({
    required this.text,
    required this.keyword,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final highlightStyle = (style ?? const TextStyle()).copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w800,
    );
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final kw = keyword.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lower.indexOf(kw, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + keyword.length),
        style: highlightStyle,
      ));
      start = idx + keyword.length;
    }
    return RichText(
      text: TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
