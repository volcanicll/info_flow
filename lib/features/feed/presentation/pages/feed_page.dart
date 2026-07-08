import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/animated_entrance.dart';
import '../../../../shared/widgets/article_card_shimmer.dart';
import '../controllers/feed_controller.dart';
import '../widgets/article_card.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canvas = theme.scaffoldBackgroundColor;
    final brand = theme.colorScheme.primary;
    final t1 = theme.textTheme.headlineLarge?.color ?? Colors.black;
    final t3 = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: canvas,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Row(
                    children: [
                      Text('InfoFlow',
                          style: theme.textTheme.headlineLarge),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            width: 40, height: 40,
                            child: Icon(Icons.notifications_none_rounded, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/search'),
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            width: 40, height: 40,
                            child: Icon(Icons.search_rounded, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: brand,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: 0),
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
                    overlayColor:
                        WidgetStateProperty.all(Colors.transparent),
                    tabs: const [
                      Tab(text: '推荐'),
                      Tab(text: '关注'),
                      Tab(text: '热榜'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: [
                _ArticleList(feedType: FeedType.recommend),
                _ArticleList(feedType: FeedType.following),
                _ArticleList(feedType: FeedType.hot),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleList extends ConsumerStatefulWidget {
  final FeedType feedType;
  const _ArticleList({required this.feedType});

  @override
  ConsumerState<_ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends ConsumerState<_ArticleList>
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(feedControllerProvider(widget.feedType).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final articlesAsync =
        ref.watch(feedControllerProvider(widget.feedType));
    final notifier =
        ref.read(feedControllerProvider(widget.feedType).notifier);
    final library = ref.watch(libraryStoreProvider);
    final unreadCount =
        articlesAsync.valueOrNull?.where((a) => !library.isRead(a.id)).length ?? 0;

    return Column(
      children: [
        // Mark all read bar
        if (unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '$unreadCount 篇新内容',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w400,
                      ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _markAllRead(),
                  child: Text(
                    '全部已读',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => notifier.refresh(),
            child: articlesAsync.when(
              loading: () => ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                itemCount: 4,
                itemBuilder: (_, __) => const ArticleCardShimmer(),
              ),
              error: (err, stack) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 120),
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 48,
                              color: theme.textTheme.bodySmall?.color),
                          const SizedBox(height: 16),
                          Text('加载失败', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('网络连接异常，请检查后重试',
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => ref.invalidate(
                                feedControllerProvider(widget.feedType)),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 120),
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.article_outlined,
                                  size: 48,
                                  color: theme.textTheme.bodySmall?.color),
                              const SizedBox(height: 16),
                              Text('暂无内容',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('下拉刷新或添加订阅源',
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemCount: articles.length + (notifier.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == articles.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final cardType = CardType.values[index % CardType.values.length];
                    return AnimatedEntrance(
                      index: index,
                      child: ArticleCard(
                        article: articles[index],
                        cardType: cardType,
                        onTap: () =>
                            context.push('/reader/${articles[index].id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _markAllRead() {
    final articles =
        ref.read(feedControllerProvider(widget.feedType)).valueOrNull;
    if (articles == null || articles.isEmpty) return;
    for (final article in articles) {
      ref.read(libraryStoreProvider.notifier).markRead(article.id);
    }
  }

  ThemeData get theme => Theme.of(context);
}
