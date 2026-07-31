import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 栏目标签：无底色、仅文字 + 大字距的分类标签。
///
/// 替代传统彩色圆角 chip —— 杂志风靠字距与全大写传达「标签感」，
/// 而非底色块。默认用编辑红作强调，也可传 [color] 覆盖。
class KickerTag extends StatelessWidget {
  final String label;

  /// 文字颜色。默认取 `context.colors.accent`。
  final Color? color;

  /// 是否全大写（英文/拼音场景）。中文标签保持 false。
  final bool uppercase;

  /// 左侧是否带一个小墨点（· 分隔感）。
  final bool leadingDot;

  final double fontSize;

  const KickerTag(
    this.label, {
    super.key,
    this.color,
    this.uppercase = false,
    this.leadingDot = false,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tagColor = color ?? c.accent;
    final text = uppercase ? label.toUpperCase() : label;

    final textWidget = Text(
      text,
      style: TextStyle(
        color: tagColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        height: 1.0,
      ),
    );

    if (!leadingDot) return textWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle),
        ),
        textWidget,
      ],
    );
  }
}
