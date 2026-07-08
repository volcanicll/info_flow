import 'dart:math';

import 'package:flutter/material.dart';

/// 列表项进场动画：淡入 + 轻微上移。按 [index] 做交错延迟，
/// 仅首次挂载播放一次，列表重渲染（如刷新）不会重复触发。
///
/// 用于信息流 / 脉搏列表，消除卡片「啪」地出现的生硬感。
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration stagger;
  final double offset;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 380),
    this.stagger = const Duration(milliseconds: 45),
    this.offset = 8,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offset / 200),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    // 交错延迟：前若干项依次进场，避免长列表一次性涌入
    final delay = widget.stagger * min(widget.index, 12);
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
