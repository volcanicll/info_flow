import 'package:flutter/material.dart';

import '../../../feed/presentation/widgets/feed_tab_bar.dart';

/// 收藏页 Tab 栏（复用信息流的胶囊指示器风格）
class BookmarkTabBar extends StatelessWidget implements PreferredSizeWidget {
  const BookmarkTabBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TabBar(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tabAlignment: TabAlignment.start,
      isScrollable: false,
      tabs: const [
        Tab(text: '全部'),
        Tab(text: '文章'),
        Tab(text: '稍后阅读'),
      ],
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      unselectedLabelStyle: const TextStyle(fontSize: 15),
      labelColor: theme.textTheme.titleLarge?.color,
      unselectedLabelColor: theme.textTheme.bodySmall?.color,
      indicatorSize: TabBarIndicatorSize.label,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      indicator: UnderlinePillIndicator(color: theme.colorScheme.primary),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}
