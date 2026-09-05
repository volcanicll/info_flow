import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/widgets/article_row.dart';

/// 收藏页（剪报集）：按日期分组的杂志日期头 + 复用信息流目录行，
/// 底部保留收藏统计条。
class BookmarkPage extends ConsumerStatefulWidget {
  const BookmarkPage({super.key});

  @override
  ConsumerState<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends ConsumerState<BookmarkPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final library = ref.watch(libraryStoreProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('剪报集 · SCRAPBOOK',
                      style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
                  const SizedBox(height: 2),
                  Text('收藏', style: theme.textTheme.displayMedium),
                ],
              ),
            ),
            _SectionTabs(controller: _tab),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _ClippingList(filter: BookmarkFilter.all),
                  _ClippingList(filter: BookmarkFilter.readLater),
                ],
              ),
            ),
            _BookmarkStats(library: library),
          ],
        ),
      ),
    );
  }
}

/// 衬线栏目切换：全部 / 稍后读。
class _SectionTabs extends StatelessWidget {
  final TabController controller;
  const _SectionTabs({required this.controller});

  static const _labels = ['全部收藏', '稍后阅读'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = controller.index == i;
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_labels[i],
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: active ? c.ink : c.inkTertiary,
                      )),
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

enum BookmarkFilter { all, readLater }

/// 可左滑移除的剪报行：整行向左滑出，移除收藏（全部标签）
/// 或取消稍后阅读（稍后读标签），带触觉反馈。
class _DismissibleRow extends ConsumerWidget {
  final Article article;
  final BookmarkFilter filter;
  final VoidCallback onTap;

  const _DismissibleRow({
    required this.article,
    required this.filter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context);
    final isReadLater = article.isReadLater;

    return Dismissible(
      key: ValueKey('clip_${article.id}_$filter'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.32},
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        final notifier = ref.read(libraryStoreProvider.notifier);
        if (filter == BookmarkFilter.all) {
          notifier.toggleBookmark(article);
        } else {
          notifier.toggleReadLater(article);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(filter == BookmarkFilter.all ? '已移除收藏' : '已移出稍后阅读'),
            duration: const Duration(milliseconds: 1600),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 26),
        color: c.surface2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReadLater ? Icons.access_time_rounded : Icons.delete_outline_rounded,
              size: 18,
              color: c.inkTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              filter == BookmarkFilter.all ? '移除收藏' : '移出稍后读',
              style: theme.textTheme.labelMedium?.copyWith(color: c.inkTertiary),
            ),
          ],
        ),
      ),
      child: ArticleRow(article: article, onTap: onTap),
    );
  }
}

class _ClippingList extends ConsumerWidget {
  final BookmarkFilter filter;
  const _ClippingList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final library = ref.watch(libraryStoreProvider);

    final items = switch (filter) {
      BookmarkFilter.all => library.bookmarks,
      BookmarkFilter.readLater =>
        library.bookmarks.where((a) => a.isReadLater).toList(),
    };

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 80),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bookmark_border_rounded, size: 44, color: c.hairlineStrong),
                const SizedBox(height: 14),
                Text('剪报集空空如也', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('点击文章的收藏按钮，内容会剪存在这里',
                    textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              ]),
            ),
          ),
        ],
      );
    }

    // 按日期分组（保持 bookmarks 原有顺序，最新在前）。
    final groups = <String, List<Article>>{};
    for (final a in items) {
      groups.putIfAbsent(_dateKey(a.publishedAt), () => []).add(a);
    }

    final children = <Widget>[];
    groups.forEach((label, list) {
      children.add(_DateHeader(label: label, count: list.length));
      for (var i = 0; i < list.length; i++) {
        if (i > 0) children.add(const Hairline());
        children.add(_DismissibleRow(
          article: list[i],
          filter: filter,
          onTap: () => context.push('/reader/${list[i].id}'),
        ));
      }
    });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }

  String _dateKey(DateTime? time) {
    if (time == null) return '未标注日期';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(time.year, time.month, time.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (time.year == now.year) return '${time.month} 月 ${time.day} 日';
    return '${time.year} 年 ${time.month} 月';
  }
}

/// 杂志日期头：kicker 日期 + 篇数 + 右侧延伸发丝线。
class _DateHeader extends StatelessWidget {
  final String label;
  final int count;
  const _DateHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          Text('$count 篇',
              style: theme.textTheme.labelMedium?.copyWith(color: c.inkTertiary)),
          const SizedBox(width: 12),
          Expanded(child: Hairline(color: c.hairlineStrong)),
        ],
      ),
    );
  }
}

class _BookmarkStats extends StatelessWidget {
  final LibraryState library;
  const _BookmarkStats({required this.library});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '${library.bookmarkCount}', label: '总收藏'),
          _StatDivider(),
          _StatItem(value: '${library.readLaterCount}', label: '稍后阅读'),
          _StatDivider(),
          _StatItem(value: '${library.readIds.length}', label: '已读'),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Hairline(vertical: true, length: 26, color: context.colors.hairlineStrong);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: AppTheme.mono(theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w800,
          ))),
      const SizedBox(height: 2),
      Text(label, style: theme.textTheme.labelMedium?.copyWith(color: c.inkTertiary)),
    ]);
  }
}
