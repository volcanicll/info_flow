import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/article_cache.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/widgets/article_card.dart';

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

    final cache = ref.read(articleCacheProvider);
    final lower = text.toLowerCase();
    final results = cache.values.where((a) {
      return a.title.toLowerCase().contains(lower) ||
          (a.summary?.toLowerCase().contains(lower) ?? false) ||
          a.feedName.toLowerCase().contains(lower);
    }).toList()
      ..sort((a, b) {
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
    final brightness = theme.brightness;

    return Scaffold(
      body: Column(
        children: [
          // Header with search input
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 18, 12),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop(),
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
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _doSearch,
                      decoration: InputDecoration(
                        hintText: '搜索已抓取的 142 篇文章…',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 19, color: theme.textTheme.bodySmall?.color),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    size: 18, color: theme.textTheme.bodySmall?.color),
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
              ],
            ),
          ),
          // Content
          Expanded(
            child: _hasSearched
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
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 22),
        ),
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
    final brightness = theme.brightness;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        // Hot tags
        Text('热门搜索', style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 9,
          children: [
            _HotTag(text: 'GPT-5', rank: '1', onTap: () => onTapHistory('GPT-5')),
            _HotTag(text: '比亚迪财报', rank: '2', onTap: () => onTapHistory('比亚迪财报')),
            _HotTag(text: 'Rust 异步闭包', rank: '3', onTap: () => onTapHistory('Rust 异步闭包')),
            _HotTag(text: 'Vision Pro 2', rank: '4', onTap: () => onTapHistory('Vision Pro 2')),
            _HotTag(text: 'DeepMind', rank: '5', onTap: () => onTapHistory('DeepMind')),
          ],
        ),
        const SizedBox(height: 24),
        // History
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('搜索历史', style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            )),
            if (history.isNotEmpty)
              GestureDetector(
                onTap: onClearHistory,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 14, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 3),
                    Text('清空', style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    )),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('还没有搜索记录',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                )),
          )
        else
          ...history.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => onTapHistory(h),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 17, color: AppTheme.hairStrong(brightness)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(h, style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                        )),
                      ),
                      Icon(Icons.north_west_rounded,
                          size: 14, color: AppTheme.hairStrong(brightness)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _HotTag extends StatelessWidget {
  final String text;
  final String rank;
  final VoidCallback? onTap;
  const _HotTag({required this.text, required this.rank, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.hair(brightness)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rank, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.down(brightness),
            )),
            const SizedBox(width: 5),
            Text(text, style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyLarge?.color,
            )),
          ],
        ),
      ),
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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: AppTheme.hairStrong(theme.brightness)),
              const SizedBox(height: 14),
              Text('未找到「$keyword」相关内容',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('换个关键词试试',
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
        return ArticleCard(
          article: a,
          onTap: () => context.push('/reader/${a.id}'),
        );
      },
    );
  }
}
