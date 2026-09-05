import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'hairline.dart';
import 'press_scale.dart';

/// 主框架：生产级链上终端底栏 + 发丝线分隔，激活态为墨线下划线。
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(Icons.radar_rounded, '雷达'),
    _TabItem(Icons.newspaper_rounded, '情报'),
    _TabItem(Icons.travel_explore_rounded, '探测'),
    _TabItem(Icons.psychology_rounded, '投研'),
    _TabItem(Icons.person_outline_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.paper,
          border: Border(top: BorderSide(color: c.hairlineStrong, width: 0.5)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 10,
            bottom: 12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final active = navigationShell.currentIndex == i;
              return Expanded(
                child: _TabButton(
                  item: _tabs[i],
                  active: active,
                  onTap: () => navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.ink : c.inkTertiary;

    return PressScale(
      pressedScale: 0.92,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 23, color: color),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: active ? 16 : 0,
            child: active
                ? Hairline(thickness: 2, color: c.accent)
                : const SizedBox(height: 2),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}
