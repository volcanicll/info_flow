import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/subscription_store.dart';
import '../../../feed/data/rss_sources.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  void _showAddSourceSheet() {
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
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('添加自定义订阅源',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '输入任意 RSS/Atom 订阅地址，订阅后将出现在信息流中。',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
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
                        .map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.label),
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
                          await ref
                              .read(subscriptionStoreProvider.notifier)
                              .addCustomSource(name, url, selectedCategory);
                          final id =
                              'custom_${name.hashCode}_${url.hashCode}';
                          await ref
                              .read(subscriptionStoreProvider.notifier)
                              .toggle(id);
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

  void _showMatchDialog() {
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
                _showAddSourceSheet();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showSourceOptions(BuildContext ctx, CustomSourceData source) {
    showModalBottomSheet(
      context: ctx,
      showDragHandle: true,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(source.name,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                source.feedUrl,
                style: Theme.of(ctx).textTheme.bodySmall
                    ?.copyWith(fontSize: 12),
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
                    foregroundColor:
                        AppTheme.love(Theme.of(ctx).brightness),
                    side: BorderSide(
                      color: AppTheme.love(Theme.of(ctx).brightness)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final subscribed = ref.watch(subscriptionStoreProvider);
    final store = ref.read(subscriptionStoreProvider.notifier);
    final customSources = store.customSources;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _PageHeader(
              title: '订阅管理',
              trailing: _IconBtn(
                icon: Icons.add_rounded,
                onTap: _showAddSourceSheet,
              ),
            ),
          ),
          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.rss_feed_rounded,
                      label: '添加 RSS',
                      onTap: _showMatchDialog,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.upload_file_rounded,
                      label: '导入 OPML',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OPML 导入功能开发中')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.explore_rounded,
                      label: '发现源',
                      onTap: () => _showDiscoverSources(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Stats card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: brightness == Brightness.dark
                        ? _brandGradientDark
                        : _brandGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCell(
                        value: '${subscribed.length}',
                        label: '已订阅',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _StatCell(
                        value: '${FeedCategory.values.length}',
                        label: '分类',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const Expanded(
                      child: _StatCell(value: '∞', label: '实时更新'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Categories
          for (final category in FeedCategory.values)
            ..._buildCategory(context, category, subscribed, customSources),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  List<Widget> _buildCategory(
    BuildContext context,
    FeedCategory category,
    Set<String> subscribed,
    List<CustomSourceData> customSources,
  ) {
    final builtInSources = RssSources.byCategory(category);
    final customInCategory = customSources
        .where((c) => c.categoryName == category.name)
        .map((c) => c.toRssSource())
        .toList();
    final sources = [...builtInSources, ...customInCategory];
    if (sources.isEmpty) return [];

    final theme = Theme.of(context);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sources.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final source = sources[index];
            final isSub = subscribed.contains(source.id);
            final isCustom = source.id.startsWith('custom_');
            return _SourceItem(
              source: source,
              isSubscribed: isSub,
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
                        _showSourceOptions(context, customSrc);
                      }
                    }
                  : null,
            );
          },
          childCount: sources.length,
        ),
      ),
    ];
  }
}

void _showDiscoverSources(BuildContext ctx) {
  showModalBottomSheet(
    context: ctx,
    showDragHandle: true,
    builder: (sheetCtx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('发现源', style: Theme.of(sheetCtx).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('推荐以下热门订阅源',
              style: Theme.of(sheetCtx).textTheme.bodySmall),
          const SizedBox(height: 14),
          ...RssSources.all.take(6).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _SourceIcon(source: s),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(s.description,
                              style: Theme.of(sheetCtx).textTheme.bodySmall
                                  ?.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(sheetCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('更多发现源功能即将上线')),
              );
            },
            child: const Text('查看更多 →'),
          ),
        ],
      ),
    ),
  );
}

const _brandGradient = [Color(0xFF5B5BD6), Color(0xFF8B5CF6)];
const _brandGradientDark = [Color(0xFF9B9BF5), Color(0xFFA78BFA)];

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(height: 5),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SourceItem extends StatelessWidget {
  final RssSource source;
  final bool isSubscribed;
  final bool isCustom;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  const _SourceItem({
    required this.source,
    required this.isSubscribed,
    this.isCustom = false,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final brand = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.hair(brightness)),
          ),
          child: Row(
            children: [
              _SourceIcon(source: source),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            source.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.tint(brightness),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '自定义',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: brand,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      source.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSubscribed
                        ? AppTheme.surface2(brightness)
                        : brand,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isSubscribed ? '已订阅' : '订阅',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSubscribed
                          ? theme.textTheme.bodySmall?.color
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  final RssSource source;
  const _SourceIcon({required this.source});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final size = 40.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: CachedNetworkImage(
        imageUrl: source.faviconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (ctx, __, ___) => _fallback(ctx, size, brightness),
        placeholder: (ctx, __) => _fallback(ctx, size, brightness),
      ),
    );
  }

  Widget _fallback(BuildContext ctx, double size, Brightness brightness) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.tint(brightness),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: Text(
          source.name.isNotEmpty ? source.name[0] : '?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Theme.of(ctx).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _PageHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.headlineLarge),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}
