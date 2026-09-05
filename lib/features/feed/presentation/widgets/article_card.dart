import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../features/signal_hub/presentation/widgets/ticker_chip.dart';
import '../../domain/entities/article.dart';
import 'article_row.dart';

/// 卡片形态。杂志目录式下仅保留头条/目录行两态，其余为兼容旧枚举保留。
enum CardType { largeImage, standard, multiImage, textOnly }

/// 文章卡：杂志目录行形态（默认），供信息流普通条目与收藏/搜索列表复用。
///
/// 头条大卡见 [ArticleHeadlineCard]。
class ArticleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ArticleRow(article: article, onTap: onTap);
  }
}

// ─── 共享排版零件 ──────────────────────────────────────────────

/// 来源行：栏目式来源名（编辑红 kicker 感）+ 时间。
class ArticleSourceLine extends StatelessWidget {
  final Article article;
  final bool isRead;
  const ArticleSourceLine({
    super.key,
    required this.article,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Flexible(
          child: Text(
            article.feedName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: c.accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('·', style: TextStyle(color: c.inkTertiary, fontSize: 11)),
        const SizedBox(width: 8),
        Text(
          formatArticleTime(article.publishedAt),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: c.inkTertiary,
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

/// AI 摘要标记：无底色，仅编辑红小字 + 图标。
class AiSummaryTag extends StatelessWidget {
  const AiSummaryTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 11, color: c.accent),
        const SizedBox(width: 4),
        Text(
          'AI 摘要',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: c.accent,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 标的标签行：最多渲染 4 个 [TickerChip]。
class ArticleTickers extends StatelessWidget {
  final Article article;
  const ArticleTickers({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    if (article.tickers.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children:
          article.tickers.take(4).map((t) => TickerChip(ref: t)).toList(),
    );
  }
}

/// 缩略图：无圆角膨胀，细发丝线描边（杂志图片处理）。
/// 传入 [heroTag] 时启用 Hero 转场（列表 → 阅读器封面），tag 需全局唯一。
class ArticleThumb extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final String? heroTag;
  const ArticleThumb({
    super.key,
    required this.url,
    this.width = 96,
    this.height = 96,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            Container(width: width, height: height, color: c.surface2),
        errorWidget: (_, _, _) => Container(
          width: width,
          height: height,
          color: c.surface2,
          child: Icon(Icons.broken_image_outlined,
              size: 20, color: c.hairlineStrong),
        ),
      ),
    );
    if (heroTag == null || heroTag!.isEmpty) return thumb;
    return Hero(tag: heroTag!, child: thumb);
  }
}

/// 已读标记：极简墨色小字，无底色块。
class ReadBadge extends StatelessWidget {
  const ReadBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_rounded, size: 11, color: c.inkTertiary),
        const SizedBox(width: 2),
        Text('已读',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: c.inkTertiary)),
      ],
    );
  }
}

String formatArticleTime(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${time.month}/${time.day}';
}
