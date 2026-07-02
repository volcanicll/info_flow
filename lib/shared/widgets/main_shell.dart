import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(Icons.graphic_eq_rounded, '脉搏'),
    _TabItem(Icons.article_outlined, '信息流'),
    _TabItem(Icons.auto_awesome_outlined, 'AI'),
    _TabItem(Icons.bookmark_border_rounded, '收藏'),
    _TabItem(Icons.person_outline_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final brand = theme.colorScheme.primary;
    final t3 = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: surface.withValues(alpha: 0.88),
              border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
            ),
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 14 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = navigationShell.currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => navigationShell.goBranch(i,
                        initialLocation: i == navigationShell.currentIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _tabs[i].icon,
                                  size: 24,
                                  color: active ? brand : t3,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tabs[i].label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: active ? brand : t3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active)
                            Positioned(
                              top: 0,
                              child: Container(
                                width: 24,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: brand,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}
