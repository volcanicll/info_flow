import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/feed_controller.dart';
import '../widgets/article_card.dart';
import '../widgets/feed_tab_bar.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfoFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: FeedTabBar(controller: _tabController),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ArticleList(feedType: FeedType.recommend),
          _ArticleList(feedType: FeedType.following),
          _ArticleList(feedType: FeedType.hot),
        ],
      ),
    );
  }
}

class _ArticleList extends ConsumerWidget {
  final FeedType feedType;

  const _ArticleList({required this.feedType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(feedControllerProvider(feedType));

    return articlesAsync.when(
      loading: () => const _LoadingList(),
      error: (err, stack) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(feedControllerProvider(feedType)),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return const _EmptyView();
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(feedControllerProvider(feedType).notifier)
              .refresh(),
          child: ListView.builder(
            itemCount: articles.length + 1,
            itemBuilder: (context, index) {
              if (index == articles.length) {
                // 加载更多
                ref.read(feedControllerProvider(feedType).notifier).loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
                );
              }
              return ArticleCard(
                article: articles[index],
                onTap: () => context.push('/reader/${articles[index].id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: MediaQuery.sizeOf(context).width * 0.7,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: theme.colorScheme.error),
            ),
            const SizedBox(height: 20),
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('网络连接异常，请检查后重试',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: Icon(Icons.article_outlined,
                  size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('暂无内容', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('下拉刷新或添加订阅源获取个性化内容',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
