import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '全部'),
                Tab(text: '文章'),
                Tab(text: '稍后阅读'),
              ],
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 15),
              indicatorSize: TabBarIndicatorSize.label,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _BookmarkList(),
                  _BookmarkList(),
                  _BookmarkList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bookmarks = List.generate(5, (i) => (
      title: ['GPT-5 发布', 'Flutter 4.0 新特性', 'Rust 后端实践', 'AI Agent 范式', 'WebAssembly 3.0'][i],
      source: ['36氪', '少数派', 'InfoQ', '极客公园', '机器之心'][i],
      time: ['2小时前', '昨天', '3天前', '1周前', '2周前'][i],
    ));

    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final item = bookmarks[index];
        return ListTile(
          title: Text(item.title, style: theme.textTheme.titleSmall),
          subtitle: Text('${item.source} · ${item.time}', style: theme.textTheme.bodySmall),
          trailing: IconButton(
            icon: Icon(Icons.bookmark, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
          onTap: () => context.push('/reader/article_$index'),
        );
      },
    );
  }
}
