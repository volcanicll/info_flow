import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/subscription_store.dart';
import '../../../feed/data/rss_sources.dart';

/// 订阅管理页
///
/// 展示真实可订阅的 RSS 源，按分类分组。
/// 顶部为快捷操作区，下方为分组源列表（含 favicon 图标、分类色、未读占位）。
class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscribed = ref.watch(subscriptionStoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('订阅管理'), actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () => _showAddSubscription(context, ref),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 快捷操作
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.rss_feed_rounded,
                  label: '添加 RSS',
                  onTap: () => _showAddSubscription(context, ref),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.upload_file_rounded,
                  label: '导入 OPML',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.explore_rounded,
                  label: '发现源',
                  onTap: () {},
                ),
              ],
            ),
          ),
          // 统计概览
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme.brightness == Brightness.dark
                      ? AppThemeBrand.brandGradientDark
                      : AppThemeBrand.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                      color: Colors.white.withValues(alpha: 0.3)),
                  Expanded(
                    child: _StatCell(
                      value: '${FeedCategory.values.length}',
                      label: '分类',
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.3)),
                  const Expanded(
                    child: _StatCell(value: '∞', label: '实时更新'),
                  ),
                ],
              ),
            ),
          ),
          // 分类源列表
          for (final category in FeedCategory.values)
            _SubscriptionGroup(
              category: category,
              sources: RssSources.byCategory(category),
              subscribed: subscribed,
              onToggle: (id) =>
                  ref.read(subscriptionStoreProvider.notifier).toggle(id),
            ),
        ],
      ),
    );
  }

  void _showAddSubscription(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加订阅'),
        content: TextField(
          controller: urlController,
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
              final url = urlController.text.trim();
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('暂不支持自定义 RSS 地址，请从下方列表中选择')),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

/// 用于订阅页内访问品牌渐变（避免循环依赖，本地别名）
class AppThemeBrand {
  static const List<Color> brandGradient = [Color(0xFF5B5BD6), Color(0xFF8B5CF6)];
  static const List<Color> brandGradientDark = [Color(0xFF9B9BF5), Color(0xFFA78BFA)];
}

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

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(height: 6),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionGroup extends StatelessWidget {
  final FeedCategory category;
  final List<RssSource> sources;
  final Set<String> subscribed;
  final void Function(String sourceId) onToggle;

  const _SubscriptionGroup({
    required this.category,
    required this.sources,
    required this.subscribed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.titleLarge?.color,
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
        for (final source in sources)
          _SourceTile(
            source: source,
            isSubscribed: subscribed.contains(source.id),
            onToggle: () => onToggle(source.id),
          ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final RssSource source;
  final bool isSubscribed;
  final VoidCallback onToggle;

  const _SourceTile({
    required this.source,
    required this.isSubscribed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onToggle,
      leading: _SourceAvatar(source: source),
      title: Text(
        source.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        source.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSubscribed
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isSubscribed ? '已订阅' : '订阅',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSubscribed
                ? theme.colorScheme.onSurfaceVariant
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SourceAvatar extends StatelessWidget {
  final RssSource source;
  const _SourceAvatar({required this.source});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: source.faviconUrl,
      width: 40,
      height: 40,
      imageBuilder: (context, provider) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image: provider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (_, _) => _fallback(context),
      errorWidget: (_, _, _) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            source.color,
            Color.lerp(source.color, Colors.white, 0.25)!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          source.name.isNotEmpty ? source.name[0] : '?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
