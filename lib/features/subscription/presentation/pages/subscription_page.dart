import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/subscription_store.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../feed/data/rss_sources.dart';
import '../widgets/source_card.dart';
import '../widgets/opml_sheets.dart';
import '../widgets/subscription_sheets.dart';

/// 订阅管理（刊物架）：分栏目陈列订阅源，细边框卡片 + 衬线刊名。
class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final subscribed = ref.watch(subscriptionStoreProvider);
    final store = ref.read(subscriptionStoreProvider.notifier);
    final customSources = store.customSources;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
                child: Row(
                  children: [
                    IconBtn(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LIBRARY · 刊物架',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: c.accent)),
                          const SizedBox(height: 2),
                          Text('订阅管理', style: theme.textTheme.displayMedium),
                        ],
                      ),
                    ),
                    IconBtn(
                        icon: Icons.add_rounded,
                        onTap: () => showAddSourceSheet(context, ref)),
                  ],
                ),
              ),
            ),
            // 订阅概览：等宽数字，发丝线分隔
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    _StatCell(value: '${subscribed.length}', label: '已订阅'),
                    Hairline(
                        vertical: true, length: 34, color: c.hairlineStrong),
                    _StatCell(
                        value: '${FeedCategory.values.length}', label: '分类'),
                    Hairline(
                        vertical: true, length: 34, color: c.hairlineStrong),
                    _StatCell(value: '${customSources.length}', label: '自定义'),
                  ],
                ),
              ),
            ),
            // 快捷操作
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(
                  children: [
                    _QuickAction(
                        label: '添加 RSS',
                        onTap: () => showMatchDialog(context, ref)),
                    const SizedBox(width: 20),
                    _QuickAction(
                        label: '发现源',
                        onTap: () => showDiscoverSources(context, ref)),
                    const SizedBox(width: 20),
                    _QuickAction(
                      label: '导入 OPML',
                      onTap: () => showOpmlImportSheet(context, ref),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      label: '导出 OPML',
                      onTap: () => showOpmlExportSheet(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            // 分栏目刊物架
            for (final category in FeedCategory.values)
              ..._buildCategory(context, ref, category, subscribed,
                  customSources),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategory(
    BuildContext context,
    WidgetRef ref,
    FeedCategory category,
    Set<String> subscribed,
    List<CustomSourceData> customSources,
  ) {
    final builtIn = RssSources.byCategory(category);
    final customInCategory = customSources
        .where((c) => c.categoryName == category.name)
        .map((c) => c.toRssSource())
        .toList();
    final sources = [...builtIn, ...customInCategory];
    if (sources.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          kicker: '${category.label} · ${sources.length}',
          title: category.label,
          extendRule: true,
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 158,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final source = sources[index];
              final isCustom = source.id.startsWith('custom_');
              return SourceCard(
                source: source,
                isSubscribed: subscribed.contains(source.id),
                isCustom: isCustom,
                onToggle: () => ref
                    .read(subscriptionStoreProvider.notifier)
                    .toggle(source.id),
                onLongPress: isCustom
                    ? () {
                        final store =
                            ref.read(subscriptionStoreProvider.notifier);
                        final customSrc = store.customSources
                            .where((c) => c.id == source.id)
                            .firstOrNull;
                        if (customSrc != null) {
                          showSourceOptions(context, ref, customSrc);
                        }
                      }
                    : null,
              );
            },
            childCount: sources.length,
          ),
        ),
      ),
    ];
  }
}

/// 订阅概览单元：等宽数字 + 说明。
class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTheme.mono(theme.textTheme.headlineLarge!)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  theme.textTheme.labelMedium?.copyWith(color: c.inkTertiary)),
        ],
      ),
    );
  }
}

/// 快捷操作：铅字风文字按钮（无底色）。
class _QuickAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(color: c.ink)),
          const SizedBox(height: 4),
          Container(width: 20, height: 2, color: c.accent),
        ],
      ),
    );
  }
}
