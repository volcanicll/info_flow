import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/article_cache.dart';
import '../../../feed/domain/entities/article.dart';

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
  int _activeFilter = 0;

  static const _kHistory = 'search_history';
  static const _filterLabels = ['全部', '文章', '来源', '标签'];

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

    setState(() { _loading = true; _hasSearched = true; });

    final cache = ref.read(articleCacheProvider);
    final lower = text.toLowerCase();
    final results = cache.values.where((a) {
      switch (_activeFilter) {
        case 1: return a.title.toLowerCase().contains(lower) || (a.summary?.toLowerCase().contains(lower) ?? false);
        case 2: return a.feedName.toLowerCase().contains(lower);
        case 3: return (a.sentiment?.toLowerCase().contains(lower) ?? false) || a.feedName.toLowerCase().contains(lower);
        default: return a.title.toLowerCase().contains(lower) || (a.summary?.toLowerCase().contains(lower) ?? false) ||
            a.feedName.toLowerCase().contains(lower) || (a.sentiment?.toLowerCase().contains(lower) ?? false);
      }
    }).toList()..sort((a, b) {
      final at = a.title.toLowerCase().contains(lower) ? 0 : 1;
      final bt = b.title.toLowerCase().contains(lower) ? 0 : 1;
      return at.compareTo(bt);
    });

    setState(() { _results = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 18, 12),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: const SizedBox(width: 40, height: 40,
                        child: Icon(Icons.arrow_back_rounded, size: 22)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface2(brightness),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.hair(brightness)),
                    ),
                    child: TextField(
                      controller: _searchController, focusNode: _focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _doSearch,
                      decoration: InputDecoration(
                        hintText: '搜索文章、订阅源…',
                        hintStyle: TextStyle(fontSize: 15, color: theme.textTheme.bodySmall?.color),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        prefixIcon: Icon(Icons.search_rounded, size: 19,
                            color: theme.textTheme.bodySmall?.color),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: 18,
                                    color: theme.textTheme.bodySmall?.color),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _hasSearched = false; _results = []; });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text('取消', style: TextStyle(
                      fontSize: 14, color: theme.colorScheme.primary)),
                ),
              ],
            ),
          ),
          // Filter chips
          if (_hasSearched)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: List.generate(_filterLabels.length, (i) {
                  final active = _activeFilter == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () { setState(() => _activeFilter = i); if (_hasSearched) _doSearch(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? theme.colorScheme.primary : AppTheme.surface2(brightness),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active ? theme.colorScheme.primary : AppTheme.hair(brightness),
                          ),
                        ),
                        child: Text(_filterLabels[i], style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: active ? theme.colorScheme.onPrimary : theme.textTheme.bodySmall?.color,
                        )),
                      ),
                    ),
                  );
                }),
              ),
            ),
          // Results header
          if (_hasSearched && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                Text('找到 ${_results.length} 篇相关内容',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400)),
                const Spacer(),
                Text('筛选', style: TextStyle(
                    fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          // Content
          Expanded(
            child: _hasSearched
                ? _SearchResults(results: _results, keyword: _searchController.text.trim(), loading: _loading)
                : _SearchSuggestions(history: _history, onTapHistory: _doSearch, onClearHistory: _clearHistory),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestions ──────────────────────────────────────────────────

class _SearchSuggestions extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTapHistory;
  final VoidCallback onClearHistory;
  const _SearchSuggestions({required this.history, required this.onTapHistory, required this.onClearHistory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Text('热门搜索', style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(spacing: 7, runSpacing: 9, children: [
          _HotTag(text: 'GPT-5', rank: '1'),
          _HotTag(text: '比亚迪财报', rank: '2'),
          _HotTag(text: 'Rust 异步闭包', rank: '3'),
          _HotTag(text: 'Vision Pro 2', rank: '4'),
          _HotTag(text: 'DeepMind', rank: '5'),
        ]),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('搜索历史', style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
          if (history.isNotEmpty)
            GestureDetector(
              onTap: onClearHistory,
              child: Row(children: [
                Icon(Icons.delete_outline_rounded, size: 14, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 3),
                Text('清空', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
              ]),
            ),
        ]),
        const SizedBox(height: 6),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('还没有搜索记录', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
          )
        else
          ...history.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onTapHistory(h),
              child: Row(children: [
                Icon(Icons.history_rounded, size: 17, color: AppTheme.hairStrong(brightness)),
                const SizedBox(width: 8),
                Expanded(child: Text(h, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14))),
                Icon(Icons.north_west_rounded, size: 14, color: AppTheme.hairStrong(brightness)),
              ]),
            ),
          )),
      ],
    );
  }
}

class _HotTag extends StatelessWidget {
  final String text;
  final String rank;
  const _HotTag({required this.text, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.hair(brightness)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(rank, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.down(brightness))),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color)),
      ]),
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<Article> results;
  final String keyword;
  final bool loading;
  const _SearchResults({required this.results, required this.keyword, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off_rounded, size: 48,
                color: AppTheme.hairStrong(Theme.of(context).brightness)),
            const SizedBox(height: 14),
            Text('未找到「$keyword」相关内容', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('换个关键词试试', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: results.length,
      itemBuilder: (context, index) => _HighlightCard(article: results[index], keyword: keyword),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final Article article;
  final String keyword;
  const _HighlightCard({required this.article, required this.keyword});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: () => context.push('/reader/${article.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.hair(brightness)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HighlightedText(
                text: article.title, keyword: keyword,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 15, letterSpacing: -0.1),
                maxLines: 2,
              ),
              if (article.summary != null) ...[
                const SizedBox(height: 6),
                _HighlightedText(
                  text: article.summary!, keyword: keyword,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Text(article.feedName, style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11, fontWeight: FontWeight.w400)),
                const SizedBox(width: 8),
                if (article.publishedAt != null)
                  Text(_formatTime(article.publishedAt),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle? style;
  final int? maxLines;
  const _HighlightedText({required this.text, required this.keyword, this.style, this.maxLines});

  @override
  Widget build(BuildContext context) {
    if (keyword.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final kwLower = keyword.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final idx = lower.indexOf(kwLower, start);
      if (idx == -1) { spans.add(TextSpan(text: text.substring(start))); break; }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + keyword.length),
        style: TextStyle(
          backgroundColor: AppTheme.tint(Theme.of(context).brightness),
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + keyword.length;
    }
    return Text.rich(TextSpan(children: spans, style: style),
        maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
}
