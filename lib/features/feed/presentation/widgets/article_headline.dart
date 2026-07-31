import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../domain/entities/article.dart';
import 'article_actions.dart';
import 'article_card.dart';

/// 头条大卡：大图跨栏 + 衬线大标题 + 摘要，信息流首条使用。
class ArticleHeadlineCard extends ConsumerWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleHeadlineCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final isRead = ref.watch(libraryStoreProvider).isRead(article.id);
    final hasCover = article.coverImageUrl != null;
    final hasSummary = article.summary != null;

    return PressScale(
      pressedScale: 0.99,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isRead ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '头条',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: c.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 0.5, color: c.hairlineStrong)),
                ],
              ),
              const SizedBox(height: 14),
              if (hasCover) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: CachedNetworkImage(
                    imageUrl: article.coverImageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                        height: 200, color: c.surface2),
                    errorWidget: (_, _, _) => Container(
                      height: 200,
                      color: c.surface2,
                      child: Icon(Icons.broken_image_outlined,
                          size: 24, color: c.hairlineStrong),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ArticleSourceLine(article: article, isRead: isRead),
              const SizedBox(height: 10),
              Text(
                article.title,
                style: theme.textTheme.displayMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasSummary) ...[
                const SizedBox(height: 10),
                Text(
                  article.summary!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: c.inkSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const AiSummaryTag(),
              ],
              if (article.tickers.isNotEmpty) ...[
                const SizedBox(height: 12),
                ArticleTickers(article: article),
              ],
              const SizedBox(height: 14),
              ArticleActions(article: article),
            ],
          ),
        ),
      ),
    );
  }
}
