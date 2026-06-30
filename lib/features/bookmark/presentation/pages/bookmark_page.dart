import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/widgets/article_card.dart';

class BookmarkPage extends ConsumerStatefulWidget {
  const BookmarkPage({super.key});

  @override
  ConsumerState<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends ConsumerState<BookmarkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t1 = theme.textTheme.headlineLarge?.color ?? Colors.black;
    final t3 = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final brand = theme.colorScheme.primary;

    return Scaffold(
      body: Column(
        children: [
          _PageHeader(title: '收藏'),
          SizedBox(
            height: 44,
            child: TabBar(
              controller: _tabController,
              indicatorColor: brand,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: t1,
              unselectedLabelColor: t3,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: '全部'),
                Tab(text: '文章'),
                Tab(text: '稍后阅读'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookmarkList(filter: BookmarkFilter.all),
                _BookmarkList(filter: BookmarkFilter.articles),
                _BookmarkList(filter: BookmarkFilter.readLater),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum BookmarkFilter { all, articles, readLater }

class _BookmarkList extends ConsumerStatefulWidget {
  final BookmarkFilter filter;
  const _BookmarkList({required this.filter});

  @override
  ConsumerState<_BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends ConsumerState<_BookmarkList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Bookmark data is fully local so no additional loading needed
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final library = ref.watch(libraryStoreProvider);
    final theme = Theme.of(context);

    List<Article> items;
    switch (widget.filter) {
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
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded,
                      size: 48,
                      color: AppTheme.hairStrong(theme.brightness)),
                  const SizedBox(height: 14),
                  Text('还没有收藏', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    '点击文章卡片的收藏按钮，内容会保存在这里',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 6, bottom: 32),
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
}

class _PageHeader extends StatelessWidget {
  final String title;
  const _PageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.headlineLarge),
          const Spacer(),
        ],
      ),
    );
  }
}
