import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/drop_cap_text.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../feed/domain/entities/article.dart';
import 'reader_toolbar.dart';

/// 原生阅读视图：衬线大标题、来源栏、首字下沉正文、大行高。
class ReaderNativeView extends StatelessWidget {
  final Article article;
  final ReaderPaper paper;
  final double fontSize;
  final double lineHeight;
  final ScrollController scrollController;

  const ReaderNativeView({
    super.key,
    required this.article,
    required this.paper,
    required this.fontSize,
    required this.lineHeight,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final body = article.content ?? article.summary ?? '暂无正文内容';

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 栏目 kicker
          Text(
            article.feedName.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 12),
          // 衬线大标题
          Text(
            article.title,
            style: theme.textTheme.displayMedium?.copyWith(color: paper.ink),
          ),
          const SizedBox(height: 16),
          // 作者/来源/时间栏
          _MetaLine(article: article, paper: paper),
          HairlineDivider(spacing: 20, color: c.hairline),
          if (article.coverImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(
                article.coverImageUrl!,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                frameBuilder: (ctx, child, frame, wasSync) => AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: child,
                ),
                errorBuilder: (_, _, _) =>
                    Container(height: 210, color: c.surface2),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // AI 摘要引述块（左侧编辑红竖线）
          if (article.summary != null) ...[
            _SummaryQuote(summary: article.summary!, paper: paper),
            const SizedBox(height: 24),
          ],
          // 正文，首段首字下沉
          DropCapText(
            body,
            style: TextStyle(
              fontSize: fontSize,
              height: lineHeight,
              color: paper.ink,
            ),
          ),
          if (article.sentiment != null) ...[
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InkTag(label: article.feedName, paper: paper),
                _InkTag(label: article.sentiment!, paper: paper),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final Article article;
  final ReaderPaper paper;
  const _MetaLine({required this.article, required this.paper});

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(article.url)?.host ?? article.feedName;
    final readTime = ((article.content ?? article.summary ?? '').length / 400)
        .ceil()
        .clamp(1, 30);
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: paper.inkSecondary,
      ),
      child: Row(
        children: [
          Text(_formatTime(article.publishedAt)),
          _dot(paper),
          Flexible(
            child: Text(host, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          _dot(paper),
          Text('约 $readTime 分钟'),
        ],
      ),
    );
  }

  Widget _dot(ReaderPaper paper) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text('·', style: TextStyle(color: paper.inkSecondary)),
  );
}

class _SummaryQuote extends StatelessWidget {
  final String summary;
  final ReaderPaper paper;
  const _SummaryQuote({required this.summary, required this.paper});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 13, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'AI 摘要',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: paper.inkSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _InkTag extends StatelessWidget {
  final String label;
  final ReaderPaper paper;
  const _InkTag({required this.label, required this.paper});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: paper.inkSecondary, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: paper.inkSecondary,
        ),
      ),
    );
  }
}

String _formatTime(DateTime? time) {
  if (time == null) return '未知时间';
  final diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${time.month}/${time.day}';
}
