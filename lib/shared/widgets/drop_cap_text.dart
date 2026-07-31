import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 首字下沉正文：段落首字放大为衬线大字母，杂志正文起首装饰。
///
/// 将 [text] 首字符抽出放大，其余文字环绕排布。用于 reader 正文
/// 第一段，营造编辑部长文起首的仪式感。
class DropCapText extends StatelessWidget {
  final String text;

  /// 正文样式，默认取 `bodyLarge`。
  final TextStyle? style;

  /// 首字放大倍数（相对正文字号）。
  final double capScale;

  const DropCapText(
    this.text, {
    super.key,
    this.style,
    this.capScale = 3.2,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final baseStyle = style ??
        Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 16, height: 1.7);

    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final cap = trimmed.substring(0, 1);
    final rest = trimmed.substring(1);
    final baseFont = baseStyle.fontSize ?? 16;

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                cap,
                style: AppTheme.mono(
                  TextStyle(
                    fontSize: baseFont * capScale,
                    height: 0.9,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ),
            ),
          ),
          TextSpan(text: rest, style: baseStyle),
        ],
      ),
    );
  }
}
