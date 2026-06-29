import 'package:flutter/material.dart';

/// 信息流顶部 Tab 栏
///
/// 风格化的胶囊式指示器，跟随品牌色。
class FeedTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;

  const FeedTabBar({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TabBar(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tabAlignment: TabAlignment.start,
      isScrollable: false,
      tabs: const [
        Tab(text: '推荐'),
        Tab(text: '关注'),
        Tab(text: '热榜'),
      ],
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      unselectedLabelStyle: const TextStyle(fontSize: 16),
      labelColor: theme.textTheme.titleLarge?.color,
      unselectedLabelColor: theme.textTheme.bodySmall?.color,
      indicatorSize: TabBarIndicatorSize.label,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      indicator: _UnderlinePillIndicator(color: theme.colorScheme.primary),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

/// 圆角胶囊下划线指示器
class _UnderlinePillIndicator extends Decoration {
  final Color color;
  const _UnderlinePillIndicator({required this.color});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _Painter(this, onChanged);
  }
}

class _Painter extends BoxPainter {
  final _UnderlinePillIndicator decoration;
  _Painter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final indicatorWidth = 24.0;
    final dx = offset.dx + (size.width - indicatorWidth) / 2;
    final dy = offset.dy + size.height - 4;
    final rect = Rect.fromLTWH(dx, dy, indicatorWidth, 3);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    final paint = Paint()
      ..color = decoration.color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }
}
