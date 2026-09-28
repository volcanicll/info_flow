import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 脉冲骨架块：透明度在 surface2 ↔ surface2+alpha 间呼吸循环。
///
/// 用于全站骨架屏（情报流目录行、探测结果卡等），统一「加载中」的
/// 视觉语言。与杂志风一致：无阴影、无大圆角，只有灰面明暗起伏。
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 2,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
