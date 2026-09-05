import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../feed/data/rss_sources.dart';

/// 刊物架卡片：细边框、无阴影，刊名用衬线大字，底部一行订阅态。
///
/// 杂志「刊物架」语言 —— 把订阅源当作一本本刊物陈列，
/// 靠细线边框 + 留白区隔，而非彩色圆角卡片。
class SourceCard extends StatelessWidget {
  final RssSource source;
  final bool isSubscribed;
  final bool isCustom;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  const SourceCard({
    super.key,
    required this.source,
    required this.isSubscribed,
    this.isCustom = false,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          border: Border.all(color: c.hairlineStrong, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SourceFavicon(source: source),
                const Spacer(),
                if (isCustom)
                  Text('自定义',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: c.accent, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              source.name,
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              source.description,
              style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Hairline(),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle();
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSubscribed
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    size: 15,
                    color: isSubscribed ? c.up : c.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSubscribed ? '已订阅' : '订阅',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSubscribed ? c.up : c.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 小尺寸刊头图标：favicon 优先，失败回退到刊名首字。
class _SourceFavicon extends StatelessWidget {
  final RssSource source;
  const _SourceFavicon({required this.source});

  static const double _size = 34;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: CachedNetworkImage(
        imageUrl: source.faviconUrl,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorWidget: (ctx, _, _) => _fallback(ctx),
        placeholder: (ctx, _) => _fallback(ctx),
      ),
    );
  }

  Widget _fallback(BuildContext ctx) {
    final c = ctx.colors;
    return Container(
      width: _size,
      height: _size,
      color: c.tint,
      alignment: Alignment.center,
      child: Text(
        source.name.isNotEmpty ? source.name[0] : '?',
        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: c.accent),
      ),
    );
  }
}
