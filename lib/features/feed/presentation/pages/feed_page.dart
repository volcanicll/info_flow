import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/notifications/alert_inbox.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/animated_entrance.dart';
import '../../../../shared/widgets/article_card_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/load_more_footer.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../controllers/feed_controller.dart';
import '../widgets/article_card.dart' show formatArticleTime;
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
    final unreadAlerts = ref.watch(alertInboxUnreadProvider);

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
                  showDot: unreadAlerts > 0,
                  onTap: _showNotificationsSheet,
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

  /// 打开通知中心（真实告警收件箱）；关闭时统一清未读。
  Future<void> _showNotificationsSheet() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.paper,
      isScrollControlled: true,
      builder: (sheetCtx) => const _NotificationsSheet(),
    );
    if (mounted) ref.read(alertInboxProvider.notifier).markAllRead();
  }
}

/// 通知中心：后台告警（聪明钱/破圈/价格提醒）的应用内收件箱。
/// 条目按时间倒序；点击按 payload 契约跳转（路由或网页）；关闭时清未读。
class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final entries = ref.watch(alertInboxProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('通知中心', style: theme.textTheme.headlineMedium),
                ),
                if (entries.isNotEmpty)
                  PressScale(
                    pressedScale: 0.9,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(alertInboxProvider.notifier).clearAll();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: c.inkTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '强信号与价格提醒的历史记录',
              style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
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
                    Text('暂无通知', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '命中强信号提醒时会同时出现在这里',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.inkTertiary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.heightOf(context) * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Hairline(),
                    itemBuilder: (ctx, i) {
                      final entry = entries[i];
                      return _NotificationTile(
                        entry: entry,
                        onTap: () => _openEntry(ctx, entry),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 按 payload 契约跳转：网页交系统浏览器，应用内路由 push。
  Future<void> _openEntry(BuildContext sheetCtx, AlertInboxEntry entry) async {
    HapticFeedback.selectionClick();
    Navigator.pop(sheetCtx);
    final payload = entry.payload;
    if (payload == null || payload.isEmpty) return;
    final url = notificationExternalUrl(payload);
    if (url != null) {
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {
        // 打不开外链就到此为止，不阻塞
      }
      return;
    }
    final route = notificationRoute(payload);
    if (route != null) GoRouter.of(sheetCtx).push(route);
  }
}

class _NotificationTile extends StatelessWidget {
  final AlertInboxEntry entry;
  final VoidCallback onTap;
  const _NotificationTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final isPrice = entry.kind == 'price';

    return PressScale(
      pressedScale: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isPrice
                  ? Icons.trending_up_rounded
                  : Icons.bolt_rounded,
              size: 15,
              color: entry.read ? c.inkTertiary : c.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!entry.read) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatArticleTime(entry.createdAt),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MastheadIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;
  const _MastheadIcon({required this.icon, required this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressScale(
      pressedScale: 0.85,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Icon(icon, size: 22, color: c.ink)),
            if (showDot)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.paper, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
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
  bool _loadingMore = false;

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
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final notifier =
        ref.read(feedControllerProvider(widget.feedType).notifier);
    if (!notifier.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      await notifier.loadMore();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
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
            onRefresh: () async {
              HapticFeedback.selectionClick();
              await notifier.refresh();
            },
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
                  itemCount: articles.length + 1,
                  separatorBuilder: (_, index) =>
                      index == 0 ? const SizedBox.shrink() : const Hairline(),
                  itemBuilder: (context, index) {
                    // 页脚：加载中转圈 / 静默占位 / 到底提示（共享组件）
                    if (index == articles.length) {
                      return LoadMoreFooter(
                        hasMore: notifier.hasMore,
                        loadingMore: _loadingMore,
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
    HapticFeedback.selectionClick();
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
