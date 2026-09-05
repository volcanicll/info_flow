import 'package:flutter/material.dart';

/// 数值渐变文本：行情数字从旧值平滑滚动到新值（600ms easeOutCubic）。
///
/// 用于报价、涨跌幅等高频刷新的数字——数据刷新时数字不会闪跳，
/// 而是带缓动地过渡，强化「实时行情」的触感。
class AnimatedNumberText extends StatelessWidget {
  final double value;

  /// 数字 → 展示文本的格式化函数（如保留小数位）。
  final String Function(double value) format;

  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedNumberText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      // value 变化时从当前插值位置滚向新值，实现连续滚动过渡。
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}
