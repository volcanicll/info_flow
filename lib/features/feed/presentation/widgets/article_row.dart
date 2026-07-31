import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../domain/entities/article.dart';
import 'article_actions.dart';
import 'article_card.dart';

/// 杂志目录行：kicker 来源 + 衬线标题 + 摘要两行 + 右侧小缩略图。
///
/// 信息流的默认条目形态，条目间以发丝线分隔（由列表统一绘制）。
class ArticleRow extends ConsumerWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleRow({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArticleSourceLine(article: article, isRead: isRead),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: theme.textTheme.titleLarge,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasSummary) ...[
                          const SizedBox(height: 6),
                          Text(
                            article.summary!,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasCover) ...[
                    const SizedBox(width: 14),
                    ArticleThumb(url: article.coverImageUrl!),
                  ],
                ],
              ),
              if (hasSummary) ...[
                const SizedBox(height: 10),
                const AiSummaryTag(),
              ],
              if (article.tickers.isNotEmpty) ...[
                const SizedBox(height: 10),
                ArticleTickers(article: article),
              ],
              const SizedBox(height: 12),
              ArticleActions(article: article),
            ],
          ),
        ),
      ),
    );
  }
}
