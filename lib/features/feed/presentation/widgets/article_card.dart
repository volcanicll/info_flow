import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../features/signal_hub/presentation/widgets/ticker_chip.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../domain/entities/article.dart';

/// Card type variants for the feed
enum CardType { largeImage, standard, multiImage, textOnly }

class ArticleCard extends ConsumerWidget {
  final Article article;
  final VoidCallback? onTap;
  final CardType cardType;

  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.cardType = CardType.standard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final library = ref.watch(libraryStoreProvider);
    final isLiked = library.isLiked(article.id);
    final isBookmarked = library.isBookmarked(article.id);
    final isRead = library.isRead(article.id);
    final hasCover = article.coverImageUrl != null;
    final hasAiSummary = article.summary != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PressScale(
        pressedScale: 0.985,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isRead ? 0.55 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.hair(brightness), width: 1),
              boxShadow: AppTheme.cardShadow(brightness),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feed row: avatar + name + time + read badge
                  _FeedHeader(article: article, isRead: isRead),
                  const SizedBox(height: 11),
                  // Card body varies by type
                  _buildCardBody(
                    context,
                    hasCover: hasCover,
                    hasAiSummary: hasAiSummary,
                    brightness: brightness,
                  ),
                  // 标的标签行：当文章识别出标的时渲染最多 4 个 TickerChip
                  if (article.tickers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: article.tickers
                          .take(4)
                          .map((t) => TickerChip(ref: t))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 13),
                  // Actions row
                  _ArticleActions(
                    article: article,
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

  Widget _buildCardBody(
    BuildContext context, {
    required bool hasCover,
    required bool hasAiSummary,
    required Brightness brightness,
  }) {
    switch (cardType) {
      case CardType.largeImage:
        return _LargeImageBody(article: article, hasAiSummary: hasAiSummary);
      case CardType.multiImage:
        return _MultiImageBody(article: article, hasAiSummary: hasAiSummary);
      case CardType.textOnly:
        return _TextOnlyBody(article: article, hasAiSummary: hasAiSummary);
      case CardType.standard:
      default:
        return _StandardBody(
          article: article,
          hasCover: hasCover,
          hasAiSummary: hasAiSummary,
        );
    }
  }
}

// ─── Card Body Variants ────────────────────────────────────────────

class _LargeImageBody extends StatelessWidget {
  final Article article;
  final bool hasAiSummary;
  const _LargeImageBody({required this.article, required this.hasAiSummary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (article.coverImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: article.coverImageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: double.infinity,
                height: 180,
                color: AppTheme.surface2(brightness),
              ),
              errorWidget: (_, __, ___) => Container(
                width: double.infinity,
                height: 180,
                color: AppTheme.surface2(brightness),
                child: Icon(Icons.broken_image_outlined,
                    size: 22, color: AppTheme.hairStrong(brightness)),
              ),
            ),
          ),
        const SizedBox(height: 10),
        _TitleText(text: article.title),
        if (hasAiSummary) ...[
          const SizedBox(height: 6),
          Text(
            article.summary!,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 9),
          const _AiChip(),
        ],
      ],
    );
  }
}

class _StandardBody extends StatelessWidget {
  final Article article;
  final bool hasCover;
  final bool hasAiSummary;
  const _StandardBody({
    required this.article,
    required this.hasCover,
    required this.hasAiSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleText(text: article.title),
              if (hasAiSummary) ...[
                const SizedBox(height: 6),
                Text(
                  article.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 9),
                const _AiChip(),
              ],
            ],
          ),
        ),
        if (hasCover) ...[
          const SizedBox(width: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: article.coverImageUrl!,
              width: 112,
              height: 88,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 112, height: 88,
                color: AppTheme.surface2(brightness),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 112, height: 88,
                color: AppTheme.surface2(brightness),
                child: Icon(Icons.broken_image_outlined,
                    size: 22, color: AppTheme.hairStrong(brightness)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MultiImageBody extends StatelessWidget {
  final Article article;
  final bool hasAiSummary;
  const _MultiImageBody({required this.article, required this.hasAiSummary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final images = <String>[
      if (article.coverImageUrl != null) article.coverImageUrl!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleText(text: article.title),
        if (hasAiSummary) ...[
          const SizedBox(height: 6),
          Text(
            article.summary!,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < images.length && i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 72, color: AppTheme.surface2(brightness),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 72, color: AppTheme.surface2(brightness),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (hasAiSummary) ...[
          const SizedBox(height: 9),
          const _AiChip(),
        ],
      ],
    );
  }
}

class _TextOnlyBody extends StatelessWidget {
  final Article article;
  final bool hasAiSummary;
  const _TextOnlyBody({required this.article, required this.hasAiSummary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleText(text: article.title),
        if (hasAiSummary) ...[
          const SizedBox(height: 6),
          Text(
            article.summary!,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 9),
          const _AiChip(),
        ],
        if (article.sentiment != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TagChip(label: article.feedName),
              _TagChip(label: article.sentiment!),
            ],
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface2(brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

// ─── Read Badge ────────────────────────────────────────────────────

class ReadBadge extends StatelessWidget {
  const ReadBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final up = AppTheme.up(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: up.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 11, color: up),
          const SizedBox(width: 3),
          Text('已读', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: up)),
        ],
      ),
    );
  }
}

// ─── Feed Header ───────────────────────────────────────────────────

class _FeedHeader extends StatelessWidget {
  final Article article;
  final bool isRead;
  const _FeedHeader({required this.article, this.isRead = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          _formatTime(article.publishedAt),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (isRead) ...[
          const SizedBox(width: 8),
          const ReadBadge(),
        ],
      ],
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CachedNetworkImage(
          imageUrl: iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (ctx, __, ___) => _fallback(ctx, size),
          placeholder: (ctx, __) => _fallback(ctx, size),
        ),
      );
    }
    return _fallback(context, size);
  }

  Widget _fallback(BuildContext ctx, double size) {
    final theme = Theme.of(ctx);
    final bgColor = color ?? AppTheme.tint(theme.brightness);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Text(
          feedName.isNotEmpty ? feedName[0] : '?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
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
            letterSpacing: -0.2,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
      decoration: BoxDecoration(
        color: AppTheme.tint(brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 11, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            'AI 摘要',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleActions extends ConsumerWidget {
  final Article article;
  final bool isLiked;
  final bool isBookmarked;

  const _ArticleActions({
    required this.article,
    required this.isLiked,
    required this.isBookmarked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final love = AppTheme.love(theme.brightness);
    final brand = theme.colorScheme.primary;

    return Row(
      children: [
        _ActBtn(
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
          label: article.likeCount != null && article.likeCount! > 0
              ? _formatCount(article.likeCount!)
              : null,
          isActive: isLiked,
          activeColor: love,
          onTap: () =>
              ref.read(libraryStoreProvider.notifier).toggleLike(article.id),
        ),
        _ActBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: '评论',
          onTap: () => _showCommentSheet(context),
        ),
        _ActBtn(
          icon: Icons.share_outlined,
          label: '分享',
          onTap: () => Share.share(
            '${article.title}\n${article.url}',
            subject: article.title,
          ),
        ),
        const Spacer(),
        _ActBtn(
          icon: Icons.bookmark_border_rounded,
          activeIcon: Icons.bookmark_rounded,
          isActive: isBookmarked,
          activeColor: brand,
          onTap: () =>
              ref.read(libraryStoreProvider.notifier).toggleBookmark(article),
        ),
      ],
    );
  }
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String? label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _ActBtn({
    required this.icon,
    this.activeIcon,
    this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t3 = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final color = isActive ? (activeColor ?? t3) : t3;
    final shownIcon = isActive && activeIcon != null ? activeIcon! : icon;
    return PressScale(
      pressedScale: 0.85,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: child,
              ),
              child: Icon(
                shownIcon,
                key: ValueKey(shownIcon),
                size: 17,
                color: color,
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showCommentSheet(BuildContext context) {
  final ctrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('发表评论', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '写下你的想法…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('评论功能即将上线')),
                  );
                },
                child: const Text('发送'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _formatTime(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${time.month}/${time.day}';
}

String _formatCount(int count) {
  if (count < 1000) return count.toString();
  if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '${(count / 10000).toStringAsFixed(1)}w';
}
