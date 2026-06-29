import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索文章、订阅源...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _doSearch(),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _hasSearched = false);
              },
            ),
        ],
      ),
      body: _hasSearched ? const _SearchResults() : const _SearchSuggestions(),
    );
  }

  void _doSearch() {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => _hasSearched = true);
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hotTopics = ['GPT-5', 'Flutter 4.0', 'AI Agent', 'Rust', 'Vision Pro'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('热门搜索', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hotTopics.map((topic) => ActionChip(
            label: Text(topic),
            onPressed: () {},
          )).toList(),
        ),
        const SizedBox(height: 24),
        Text('搜索历史', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.history, size: 20),
          title: Text('大模型最新进展', style: theme.textTheme.bodyMedium),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.history, size: 20),
          title: Text('Flutter 性能优化', style: theme.textTheme.bodyMedium),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('搜索结果 ${index + 1}', style: theme.textTheme.titleSmall),
          subtitle: Text('来源 · 2小时前', style: theme.textTheme.bodySmall),
          onTap: () => context.push('/reader/article_search_$index'),
        );
      },
    );
  }
}
