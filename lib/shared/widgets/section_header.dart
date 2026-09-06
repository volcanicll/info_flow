import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'hairline.dart';

/// 杂志栏目头：小号 kicker（大字距）+ 衬线大标题 + 右侧细线延伸。
///
/// 用于各页面/区块的标题栏，替代普通 [Text] 大标题，
/// 统一编辑部栏目排版语言。
class SectionHeader extends StatelessWidget {
  /// 栏目上方的小字 kicker（如 "SIGNAL" / "本期精选"）。可空。
  final String? kicker;

  /// 衬线大标题。可空（当仅需 kicker 栏目头时）。
  final String? title;

  /// 标题右侧的操作/说明控件（如「查看全部」）。
  final Widget? trailing;

  /// 快速右侧文本动作（与 onAction 配合）。
  final String? action;
  final VoidCallback? onAction;

  /// 是否在标题右侧绘制延伸发丝线。
  final bool extendRule;

  /// kicker 颜色，默认编辑红。
  final Color? kickerColor;

  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    this.title,
    this.kicker,
    this.trailing,
    this.action,
    this.onAction,
    this.extendRule = true,
    this.kickerColor,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;

    final resolvedTrailing = trailing ??
        (action != null
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(action!,
                          style:
                              textTheme.labelSmall?.copyWith(color: c.accent)),
                      Icon(Icons.chevron_right_rounded,
                          size: 14, color: c.accent),
                    ],
                  ),
                ),
              )
            : null);

    if (title == null) {
      return Padding(
        padding: padding,
        child: Row(
          children: [
            if (kicker != null)
              Expanded(
                child: Text(
                  kicker!,
                  style: textTheme.labelMedium?.copyWith(
                    color: kickerColor ?? c.inkSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Spacer(),
            if (resolvedTrailing != null) resolvedTrailing,
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kicker != null) ...[
            Text(
              kicker!,
              style: textTheme.labelMedium?.copyWith(
                color: kickerColor ?? c.accent,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title!,
                  style: textTheme.headlineMedium,
                ),
              ),
              if (extendRule) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Hairline(color: c.hairlineStrong),
                ),
              ] else
                const Spacer(),
              if (resolvedTrailing != null) ...[
                const SizedBox(width: 12),
                resolvedTrailing,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
