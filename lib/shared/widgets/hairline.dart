import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 发丝线：0.5px 极细分割线，杂志「用线不用影」的基础语言。
///
/// - [Hairline] 单条线，可横可竖，用于任意位置的细线分隔。
/// - [HairlineDivider] 带上下留白的横向分隔线，替代 [Divider]。
class Hairline extends StatelessWidget {
  /// 线的粗细（逻辑像素）。默认 0.5px。
  final double thickness;

  /// 是否竖向。默认横向。
  final bool vertical;

  /// 线的长度（横向时为高度不适用，指定宽度用 [length]）。null 则铺满。
  final double? length;

  /// 覆盖颜色，默认取 `context.colors.hairline`。
  final Color? color;

  const Hairline({
    super.key,
    this.thickness = 0.5,
    this.vertical = false,
    this.length,
    this.color,
  }) : _strong = false;

  /// 重发丝线（略深），用于需要更强分隔感的位置。
  const Hairline.strong({
    super.key,
    this.thickness = 0.5,
    this.vertical = false,
    this.length,
  }) : color = null,
       _strong = true;

  final bool _strong;

  @override
  Widget build(BuildContext context) {
    // 仅在未显式指定颜色时才读取 AppColors extension，
    // 以便在无扩展的裸 MaterialApp（如单测）中传色使用。
    final lineColor =
        color ?? (_strong ? context.colors.hairlineStrong : context.colors.hairline);
    return Container(
      width: vertical ? thickness : length,
      height: vertical ? length : thickness,
      color: lineColor,
    );
  }
}

/// 带上下留白的横向分隔线，替代 Material [Divider]。
class HairlineDivider extends StatelessWidget {
  /// 上下留白。默认 16。
  final double spacing;

  /// 左右缩进。
  final double indent;
  final double endIndent;

  final double thickness;
  final Color? color;

  const HairlineDivider({
    super.key,
    this.spacing = 16,
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 0.5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(indent, spacing, endIndent, spacing),
      child: Hairline(thickness: thickness, color: color),
    );
  }
}
