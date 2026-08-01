import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../feed/domain/entities/article.dart';
import '../controllers/reader_controller.dart';

/// 阅读纸底配色（杂志纸感四态）。
class ReaderPaper {
  final Color background;
  final Color ink;
  final Color inkSecondary;
  const ReaderPaper(this.background, this.ink, this.inkSecondary);
}

const readerPaperTones = <ReaderPaper>[
  ReaderPaper(Color(0xFFFAF9F5), Color(0xFF1A1917), Color(0xFF57534E)), // 纸白
  ReaderPaper(Color(0xFFF5EFE1), Color(0xFF33291B), Color(0xFF6B5D45)), // 暖米
  ReaderPaper(Color(0xFFE9E0CE), Color(0xFF3A2F1C), Color(0xFF6E5F44)), // 陈纸
  ReaderPaper(Color(0xFF1F1E1C), Color(0xFFEDE9E0), Color(0xFFA8A298)), // 墨夜
];

/// 极简圆形图标按钮（无底色）。
class ReaderIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const ReaderIconBtn({
    super.key,
    required this.icon,
    required this.color,
    this.size = 22,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.85,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

/// 模式切换：阅读模式 / 网页原文（墨线下划线激活态）。
class ReaderModeToggle extends StatelessWidget {
  final bool isActive;
  final String label;
  final Color ink;
  final Color inkSecondary;
  final Color accent;
  final VoidCallback onTap;
  const ReaderModeToggle({
    super.key,
    required this.isActive,
    required this.label,
    required this.ink,
    required this.inkSecondary,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.94,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? ink : inkSecondary,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isActive ? 16 : 0,
            color: accent,
          ),
        ],
      ),
    );
  }
}

/// 底部工具栏：极简墨色图标条。
class ReaderBottomBar extends ConsumerWidget {
  final Article article;
  final ReaderPaper paper;
  const ReaderBottomBar({
    super.key,
    required this.article,
    required this.paper,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final library = ref.watch(libraryStoreProvider);
    final isBookmarked = library.isBookmarked(article.id);
    final isLiked = library.isLiked(article.id);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: paper.background,
        border: Border(top: BorderSide(color: c.hairline, width: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          28,
          12,
          28,
          14 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BarAction(
              icon: isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: '点赞',
              color: isLiked ? c.love : paper.inkSecondary,
              onTap: () => ref
                  .read(libraryStoreProvider.notifier)
                  .toggleLike(article.id),
            ),
            _BarAction(
              icon: Icons.mode_comment_outlined,
              label: '评论',
              color: paper.inkSecondary,
              onTap: () => _showCommentSheet(context, article, paper),
            ),
            _BarAction(
              icon: Icons.ios_share_rounded,
              label: '分享',
              color: paper.inkSecondary,
              onTap: () => Share.share(
                '${article.title}\n${article.url}',
                subject: article.title,
              ),
            ),
            _BarAction(
              icon: isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: '收藏',
              color: isBookmarked ? c.accent : paper.inkSecondary,
              onTap: () => ref
                  .read(libraryStoreProvider.notifier)
                  .toggleBookmark(article),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCommentSheet(
  BuildContext context,
  Article article,
  ReaderPaper paper,
) {
  final ctrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.paper,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('发表评论', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '「${article.title}」',
            style: Theme.of(
              ctx,
            ).textTheme.bodySmall?.copyWith(color: ctx.colors.inkTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '写下你的想法…'),
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('评论功能即将上线')));
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

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.86,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10.5, color: color)),
        ],
      ),
    );
  }
}

/// 阅读设置面板：字号 / 行高 / 纸底。
void showReadingSettings(BuildContext context, WidgetRef ref) {
  final c = context.colors;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: c.paper,
    builder: (sheetCtx) => Consumer(
      builder: (ctx, sheetRef, _) {
        final state = sheetRef.watch(readerControllerProvider);
        final ctrl = sheetRef.read(readerControllerProvider.notifier);
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('阅读设置', style: theme.textTheme.titleLarge),
              const HairlineDivider(spacing: 16),
              _SettingRow(label: '字号', value: '${state.fontSize.round()} pt'),
              Slider(
                value: state.fontSize,
                min: 12,
                max: 24,
                divisions: 6,
                onChanged: ctrl.setFontSize,
              ),
              const SizedBox(height: 8),
              _SettingRow(
                label: '行高',
                value: state.lineHeight.toStringAsFixed(2),
              ),
              Slider(
                value: state.lineHeight,
                min: 1.3,
                max: 2.2,
                divisions: 9,
                onChanged: ctrl.setLineHeight,
              ),
              const SizedBox(height: 12),
              Text('纸底', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(readerPaperTones.length, (i) {
                  final selected = state.paperIndex == i;
                  return GestureDetector(
                    onTap: () => ctrl.setPaperIndex(i),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: readerPaperTones[i].background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? c.accent : c.hairlineStrong,
                          width: selected ? 2 : 0.5,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: readerPaperTones[i].ink,
                            )
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  const _SettingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: AppTheme.mono(theme.textTheme.bodySmall!)),
      ],
    );
  }
}
