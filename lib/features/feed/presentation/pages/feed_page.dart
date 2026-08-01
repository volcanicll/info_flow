import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/animated_entrance.dart';
import '../../../../shared/widgets/article_card_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../controllers/feed_controller.dart';
import '../widgets/article_headline.dart';
import '../widgets/article_row.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _sections = ['推荐', '关注', '热榜'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
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
    final c = context.colors;

    return Scaffold(
      body: Column(
        children: [
          // ── 报头：刊名 + 检索 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'INFOFLOW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: c.accent,
                  ),
                ),
                const Spacer(),
                _MastheadIcon(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => _showNotificationsSheet(context),
                ),
                _MastheadIcon(
                  icon: Icons.search_rounded,
                  onTap: () => context.push('/search'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('今日要闻', style: theme.textTheme.headlineLarge),
          ),
          // ── 栏目切换：衬线小字 + 墨线下划线 ──
          _SectionTabs(
            controller: _tabController,
            sections: _sections,
            onTap: (i) => _tabController.animateTo(i),
          ),
          const Hairline(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: const [
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

void _showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.paper,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final c = ctx.colors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('通知中心', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '订阅源动态与信号提醒将在此展示',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.inkTertiary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  border: Border.all(color: c.hairline, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 40,
                      color: c.hairlineStrong,
                    ),
                    const SizedBox(height: 12),
                    Text('暂无新通知', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '强信号提醒将在这里出现',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MastheadIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MastheadIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.85,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 22, color: context.colors.ink),
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  final TabController controller;
  final List<String> sections;
  final ValueChanged<int> onTap;

  const _SectionTabs({
    required this.controller,
    required this.sections,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: List.generate(sections.length, (i) {
          final active = controller.index == i;
          return Padding(
            padding: const EdgeInsets.only(right: 22),
            child: PressScale(
              pressedScale: 0.94,
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sections[i],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? c.ink : c.inkTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: active ? 18 : 0,
                    color: c.accent,
                  ),
                ],
              ),
            ),
          );
        }),
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
      ref.read(feedControllerProvider(widget.feedType).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final articlesAsync = ref.watch(feedControllerProvider(widget.feedType));
    final notifier = ref.read(feedControllerProvider(widget.feedType).notifier);
    final library = ref.watch(libraryStoreProvider);
    final unreadCount =
        articlesAsync.value?.where((a) => !library.isRead(a.id)).length ?? 0;

    return Column(
      children: [
        if (unreadCount > 0)
          _UnreadBar(count: unreadCount, onMarkAll: _markAllRead),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => notifier.refresh(),
            color: context.colors.accent,
            child: articlesAsync.when(
              loading: () => ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                itemCount: 4,
                itemBuilder: (_, _) => const ArticleCardShimmer(),
              ),
              error: (err, stack) => _ErrorView(
                onRetry: () =>
                    ref.invalidate(feedControllerProvider(widget.feedType)),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 100),
                    children: const [
                      EmptyState(
                        icon: Icons.article_outlined,
                        title: '暂无内容',
                        description: '下拉刷新或添加订阅源',
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: articles.length + (notifier.hasMore ? 1 : 0),
                  separatorBuilder: (_, index) =>
                      index == 0 ? const SizedBox.shrink() : const Hairline(),
                  itemBuilder: (context, index) {
                    if (index == articles.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final article = articles[index];
                    final child = index == 0
                        ? ArticleHeadlineCard(
                            article: article,
                            onTap: () => context.push('/reader/${article.id}'),
                          )
                        : ArticleRow(
                            article: article,
                            onTap: () => context.push('/reader/${article.id}'),
                          );
                    return AnimatedEntrance(index: index, child: child);
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
    final articles = ref.read(feedControllerProvider(widget.feedType)).value;
    if (articles == null || articles.isEmpty) return;
    for (final article in articles) {
      ref.read(libraryStoreProvider.notifier).markRead(article.id);
    }
  }
}

class _UnreadBar extends StatelessWidget {
  final int count;
  final VoidCallback onMarkAll;
  const _UnreadBar({required this.count, required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Text(
            '$count 篇未读',
            style: TextStyle(fontSize: 12, color: c.inkTertiary),
          ),
          const Spacer(),
          PressScale(
            pressedScale: 0.9,
            onTap: onMarkAll,
            child: Text(
              '全部标记已读',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: c.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 100),
      children: [
        EmptyState(
          icon: Icons.wifi_off_rounded,
          title: '加载失败',
          description: '网络连接异常，请检查后重试',
          actionLabel: '重试',
          onAction: onRetry,
        ),
      ],
    );
  }
}
