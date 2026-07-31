import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'press_scale.dart';

/// 编辑部卡片：无阴影、靠留白 + 发丝线分隔，可选细边框。
///
/// 杂志「用线不用影」—— 默认无边框，仅内边距 + 底部发丝线区隔；
/// 传 [bordered] 则四周描 0.5px 细线（用于刊物架式网格）。
class EditorialCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// 是否四周描细边框。默认 false（仅靠留白）。
  final bool bordered;

  /// 是否底部带发丝线（目录行式）。默认 false。
  final bool underline;

  final EdgeInsetsGeometry padding;

  /// 卡面底色，默认透明（贴纸底）。
  final Color? background;

  const EditorialCard({
    super.key,
    required this.child,
    this.onTap,
    this.bordered = false,
    this.underline = false,
    this.padding = const EdgeInsets.all(16),
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        border: bordered
            ? Border.all(color: c.hairline, width: 0.5)
            : underline
                ? Border(bottom: BorderSide(color: c.hairline, width: 0.5))
                : null,
        borderRadius: bordered ? BorderRadius.circular(4) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      content = PressScale(onTap: onTap, child: content);
    }
    return content;
  }
}
