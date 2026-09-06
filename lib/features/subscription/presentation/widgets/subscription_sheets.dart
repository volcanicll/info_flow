import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/subscription_store.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../feed/data/rss_sources.dart';

/// 添加自定义订阅源（添加表单）：极简铅字风底部弹窗。
void showAddSourceSheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  String selectedCategory = 'tech';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final c = ctx.colors;
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ADD SOURCE',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: c.accent)),
                const SizedBox(height: 6),
                Text('添加订阅源', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  '输入任意 RSS/Atom 订阅地址，订阅后将出现在信息流中。',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '例如：阮一峰的网络日志',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'RSS 地址',
                    hintText: 'https://example.com/feed.xml',
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: '分类'),
                  items: FeedCategory.values
                      .map((cat) => DropdownMenuItem(
                            value: cat.name,
                            child: Text(cat.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() => selectedCategory = v);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final url = urlCtrl.text.trim();
                        if (name.isEmpty || url.isEmpty) return;
                        final store =
                            ref.read(subscriptionStoreProvider.notifier);
                        await store.addCustomSource(name, url, selectedCategory);
                        final id = 'custom_${name.hashCode}_${url.hashCode}';
                        await store.toggle(id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('添加并订阅'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// 快速添加 RSS：匹配内置源，命中即订阅，否则转到自定义表单。
void showMatchDialog(BuildContext context, WidgetRef ref) {
  final urlCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('添加 RSS'),
      content: TextField(
        controller: urlCtrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '输入 RSS 地址或网站 URL',
          prefixIcon: Icon(Icons.link_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final url = urlCtrl.text.trim();
            if (url.isEmpty) return;
            final uri = Uri.tryParse(url);
            if (uri == null || !uri.hasScheme) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入有效的 URL')),
              );
              return;
            }
            Navigator.pop(ctx);
            final matched = RssSources.all.where(
              (s) =>
                  s.feedUrl == url ||
                  s.siteUrl == url ||
                  s.siteUrl.startsWith(url),
            );
            if (matched.isNotEmpty) {
              for (final s in matched) {
                ref.read(subscriptionStoreProvider.notifier).toggle(s.id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已订阅 ${matched.first.name}')),
              );
            } else {
              showAddSourceSheet(context, ref);
            }
          },
          child: const Text('添加'),
        ),
      ],
    ),
  );
}

/// 自定义源长按选项：目前提供删除。
void showSourceOptions(
    BuildContext context, WidgetRef ref, CustomSourceData source) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      final c = sheetCtx.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              source.feedUrl,
              style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(subscriptionStoreProvider.notifier)
                      .removeCustomSource(source.id);
                  Navigator.pop(sheetCtx);
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('删除此订阅源'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.down,
                  side: BorderSide(color: c.down.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 发现源：推荐若干热门订阅源。
void showDiscoverSources(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      final c = sheetCtx.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DISCOVER',
                style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
            const SizedBox(height: 6),
            Text('发现源', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('推荐以下热门订阅源',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary)),
            const SizedBox(height: 14),
            for (final s in RssSources.all.take(6)) ...[
              const Hairline(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            s.description,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: c.inkTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(subscriptionStoreProvider.notifier)
                          .toggle(s.id),
                      child: const Text('订阅'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
