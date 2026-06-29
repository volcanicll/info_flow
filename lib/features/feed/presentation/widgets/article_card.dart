import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../domain/entities/article.dart';

/// 文章卡片
///
/// 点赞 / 收藏按钮接入全局 libraryStoreProvider，与收藏页、阅读器联动。
class ArticleCard extends ConsumerWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasCover = article.coverImageUrl != null;
    final library = ref.watch(libraryStoreProvider);
    final isLiked = library.isLiked(article.id);
    final isBookmarked = library.isBookmarked(article.id);
    final isRead = library.isRead(article.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow(theme.brightness),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Opacity(
            opacity: isRead ? 0.6 : 1.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeedHeader(article: article),
                  const SizedBox(height: 12),
                  if (hasCover)
                    _CompactLayout(article: article, theme: theme)
                  else
                    _TextLayout(article: article, theme: theme),
                  const SizedBox(height: 12),
                  _ArticleActions(
                    article: article,
                    theme: theme,
                    isLiked: isLiked,
                    isBookmarked: isBookmarked,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final Article article;
  const _FeedHeader({required this.article});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FeedAvatar(
          feedName: article.feedName,
          iconUrl: article.feedIconUrl,
          color: article.feedColorValue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            article.feedName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatTime(article.publishedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final Article article;
  final ThemeData theme;
  const _CompactLayout({required this.article, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleText(text: article.title),
              if (article.summary != null) ...[
                const SizedBox(height: 6),
                Text(
                  article.summary!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (article.summary != null) ...[
                const SizedBox(height: 8),
                const _AiSummaryChip(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: article.coverImageUrl!,
            width: 110,
            height: 88,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 110,
              height: 88,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            errorWidget: (context, url, error) => Container(
              width: 110,
              height: 88,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.broken_image_outlined,
                  size: 22, color: theme.colorScheme.outline),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextLayout extends StatelessWidget {
  final Article article;
  final ThemeData theme;
  const _TextLayout({required this.article, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleText(text: article.title),
        if (article.summary != null) ...[
          const SizedBox(height: 8),
          Text(
            article.summary!,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const _AiSummaryChip(),
        ],
      ],
    );
  }
}

class _TitleText extends StatelessWidget {
  final String text;
  const _TitleText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            height: 1.38,
            letterSpacing: -0.1,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _AiSummaryChip extends StatelessWidget {
  const _AiSummaryChip();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppTheme.brandGradientDark : AppTheme.brandGradient;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome,
              size: 11, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 3),
          Text(
            'AI 摘要',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleActions extends StatelessWidget {
  final Article article;
  final ThemeData theme;
  final bool isLiked;
  final bool isBookmarked;
  const _ArticleActions({
    required this.article,
    required this.theme,
    required this.isLiked,
    required this.isBookmarked,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Row(
          children: [
            _ActionButton(
              icon: Icons.thumb_up_outlined,
              activeIcon: Icons.thumb_up,
              label: _formatCount(article.likeCount),
              isActive: isLiked,
              onTap: () => ref
                  .read(libraryStoreProvider.notifier)
                  .toggleLike(article.id),
            ),
            const SizedBox(width: 18),
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: '评论',
              onTap: () {},
            ),
            const SizedBox(width: 18),
            _ActionButton(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () {},
            ),
            const Spacer(),
            _ActionButton(
              icon: Icons.bookmark_outline_rounded,
              activeIcon: Icons.bookmark_rounded,
              isActive: isBookmarked,
              onTap: () => ref
                  .read(libraryStoreProvider.notifier)
                  .toggleBookmark(article),
            ),
          ],
        );
      },
    );
  }
}

class _FeedAvatar extends StatelessWidget {
  final String feedName;
  final String? iconUrl;
  final Color? color;
  const _FeedAvatar({required this.feedName, this.iconUrl, this.color});

  @override
  Widget build(BuildContext context) {
    final size = 22.0;
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        imageBuilder: (context, provider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: DecorationImage(image: provider, fit: BoxFit.cover),
          ),
        ),
        errorWidget: (_, _, _) => _fallback(context, size),
        placeholder: (_, _) => _fallback(context, size),
      );
    }
    return _fallback(context, size);
  }

  Widget _fallback(BuildContext context, double size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [color ?? Theme.of(context).colorScheme.primary];
    if (color != null) {
      colors.add(Color.lerp(color, Colors.white, isDark ? 0.05 : 0.25)!);
    } else if (isDark) {
      colors.add(AppTheme.brandGradientDark.last);
    } else {
      colors.add(AppTheme.brandGradient.last);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          feedName.isNotEmpty ? feedName[0] : '?',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String? label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.activeIcon,
    this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.textTheme.bodySmall?.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive && activeIcon != null ? activeIcon! : icon,
              size: 17,
              color: color,
            ),
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.isNegative) return '刚刚';
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (diff.inHours < 24) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return '${time.month}/${time.day}';
}

String _formatCount(int? count) {
  if (count == null || count == 0) return '';
  if (count < 1000) return count.toString();
  if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '${(count / 10000).toStringAsFixed(1)}w';
}
