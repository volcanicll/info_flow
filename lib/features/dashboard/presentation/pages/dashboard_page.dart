import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/article_cache.dart';
import '../../../feed/domain/entities/article.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cache = ref.watch(articleCacheProvider);
    final articles = cache.values.toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(theme)),
          if (articles.isNotEmpty)
            SliverToBoxAdapter(
              child: _TechDailySection(articles: articles),
            ),
          SliverToBoxAdapter(
            child: _MarketGrid(brightness: brightness, theme: theme),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text('市场', style: theme.textTheme.headlineLarge),
          const Spacer(),
          Icon(Icons.bar_chart_rounded,
              size: 20, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _TechDailySection extends StatelessWidget {
  final List<Article> articles;
  const _TechDailySection({required this.articles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final top = sorted.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: brightness == Brightness.dark
                ? [const Color(0xFF2D2D44), const Color(0xFF252538)]
                : [const Color(0xFFF0EEF8), const Color(0xFFF8F7FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.hair(brightness)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('今日要闻',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                    )),
                const Spacer(),
                Text('${articles.length} 篇',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < top.length; i++) ...[
              _NewsRow(index: i + 1, article: top[i]),
              if (i < top.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  final int index;
  final Article article;
  const _NewsRow({required this.index, required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('/reader/${article.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (article.summary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    article.summary!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.tint(theme.brightness),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.feedName,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeAgo(article.publishedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }
}

class _MarketGrid extends StatelessWidget {
  final Brightness brightness;
  final ThemeData theme;
  const _MarketGrid({required this.brightness, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2),
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
                Text('市场概览',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                    )),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _DashboardCard(
                  icon: Icons.radar_rounded,
                  label: '庄家雷达',
                  subtitle: '加密货币信号',
                  color: AppTheme.warn(brightness),
                  onTap: () => context.push('/crypto-radar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardCard(
                  icon: Icons.smart_toy_rounded,
                  label: 'AI 排行',
                  subtitle: 'HuggingFace 趋势',
                  color: const Color(0xFFFFD21E),
                  onTap: () => context.push('/ai-models'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardCard(
                  icon: Icons.monetization_on_outlined,
                  label: '贵金属',
                  subtitle: '实时金价银价',
                  color: const Color(0xFFD4A843),
                  onTap: () => context.push('/metals'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.hair(b)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
