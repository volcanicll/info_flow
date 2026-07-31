import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../domain/entities/article.dart';

/// 文章操作栏：点赞 / 评论 / 分享 / 收藏。
///
/// 杂志风极简墨色图标条，激活态用编辑红/语义色点缀，无底色块。
class ArticleActions extends ConsumerWidget {
  final Article article;

  const ArticleActions({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final library = ref.watch(libraryStoreProvider);
    final isLiked = library.isLiked(article.id);
    final isBookmarked = library.isBookmarked(article.id);

    return Row(
      children: [
        _ActBtn(
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
          label: article.likeCount != null && article.likeCount! > 0
              ? _formatCount(article.likeCount!)
              : null,
          isActive: isLiked,
          activeColor: c.love,
          onTap: () =>
              ref.read(libraryStoreProvider.notifier).toggleLike(article.id),
        ),
        const SizedBox(width: 18),
        _ActBtn(
          icon: Icons.mode_comment_outlined,
          label: '评论',
          onTap: () => _showCommentSheet(context),
        ),
        const SizedBox(width: 18),
        _ActBtn(
          icon: Icons.ios_share_rounded,
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
          activeColor: c.accent,
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
    final c = context.colors;
    final color = isActive ? (activeColor ?? c.inkTertiary) : c.inkTertiary;
    final shownIcon = isActive && activeIcon != null ? activeIcon! : icon;
    return PressScale(
      pressedScale: 0.85,
      onTap: onTap,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _showCommentSheet(BuildContext context) {
  final ctrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.paper,
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

String _formatCount(int count) {
  if (count < 1000) return count.toString();
  if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '${(count / 10000).toStringAsFixed(1)}w';
}
