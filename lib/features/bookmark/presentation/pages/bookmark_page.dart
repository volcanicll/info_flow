import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/library_store.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/widgets/article_card.dart';
import '../widgets/bookmark_tab_bar.dart';

/// 收藏页
///
/// 监听全局 libraryStoreProvider，展示真实持久化的收藏文章。
/// 三个 tab：全部 / 文章 / 稍后阅读。
class BookmarkPage extends ConsumerWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('收藏'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => context.push('/search'),
            ),
          ],
          bottom: const BookmarkTabBar(),
        ),
        body: const TabBarView(
          children: [
            _BookmarkList(filter: BookmarkFilter.all),
            _BookmarkList(filter: BookmarkFilter.articles),
            _BookmarkList(filter: BookmarkFilter.readLater),
          ],
        ),
      ),
    );
  }
}

enum BookmarkFilter { all, articles, readLater }

class _BookmarkList extends ConsumerWidget {
  final BookmarkFilter filter;
  const _BookmarkList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryStoreProvider);
    final theme = Theme.of(context);

    List<Article> items;
    switch (filter) {
      case BookmarkFilter.all:
        items = library.bookmarks;
        break;
      case BookmarkFilter.articles:
        items = library.bookmarks.where((a) => !a.isReadLater).toList();
        break;
      case BookmarkFilter.readLater:
        items = library.bookmarks.where((a) => a.isReadLater).toList();
        break;
    }

    if (items.isEmpty) {
      return _buildEmpty(context, theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // 收藏列表无需远程刷新，这里仅做 UI 反馈
        return;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final article = items[index];
          return ArticleCard(
            article: article,
            onTap: () => context.push('/reader/${article.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ThemeData theme) {
    String hint;
    IconData icon;
    switch (filter) {
      case BookmarkFilter.readLater:
        icon = Icons.access_time_rounded;
        hint = '在阅读文章时选择「稍后阅读」即可在此查看';
        break;
      default:
        icon = Icons.bookmark_border_rounded;
        hint = '点击文章卡片的收藏按钮，内容会保存在这里';
    }
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
              child: Icon(icon, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('还没有收藏', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
