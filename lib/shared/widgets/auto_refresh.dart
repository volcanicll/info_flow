import 'dart:async';

import 'package:flutter/material.dart';

/// 自动刷新容器：挂载期间按固定间隔触发 [onRefresh]。
///
/// 页面进入时开始计时、离开时自动取消；用于行情页的轮询刷新，
/// 让报价保持「新鲜」而不需要用户反复下拉。
class AutoRefresh extends StatefulWidget {
  final Duration interval;
  final Future<void> Function() onRefresh;
  final Widget child;

  const AutoRefresh({
    super.key,
    required this.interval,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> {
  Timer? _timer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(AutoRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) {
      _timer?.cancel();
      // 重置进行中标志：新间隔的首次 tick 不应被旧请求跳过
      _refreshing = false;
      _start();
    }
  }

  void _start() {
    _timer = Timer.periodic(widget.interval, (_) => _tick());
  }

  Future<void> _tick() async {
    if (_refreshing) return; // 上一次未完成则跳过，避免请求堆积
    // 页面被 push 覆盖（如打开详情页）时暂停轮询，返回前台再继续
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _refreshing = true;
    try {
      await widget.onRefresh();
    } catch (_) {
      // 轮询失败静默：下一轮继续尝试，不让定时器中断
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
