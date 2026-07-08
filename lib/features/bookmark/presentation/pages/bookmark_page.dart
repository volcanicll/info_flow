import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/widgets/article_card.dart';

class BookmarkPage extends ConsumerStatefulWidget {
  const BookmarkPage({super.key});

  @override
  ConsumerState<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends ConsumerState<BookmarkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t1 = theme.textTheme.headlineLarge?.color ?? Colors.black;
    final t3 = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final brand = theme.colorScheme.primary;
    final library = ref.watch(libraryStoreProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Row(
              children: [
                Text('收藏', style: theme.textTheme.headlineLarge),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showNewFolderDialog(context),
                  child: Icon(Icons.create_new_folder_outlined, size: 22, color: brand),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: TabBar(
              controller: _tabController,
              indicatorColor: brand, indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: t1, unselectedLabelColor: t3,
              labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: '文件夹'),
                Tab(text: '全部收藏'),
                Tab(text: '稍后阅读'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FolderListView(library: library, onNewFolder: () => _showNewFolderDialog(context)),
                _BookmarkList(filter: BookmarkFilter.all),
                _BookmarkList(filter: BookmarkFilter.readLater),
              ],
            ),
          ),
          _BookmarkStats(library: library),
        ],
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(controller: controller, autofocus: true,
            decoration: const InputDecoration(hintText: '输入文件夹名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('创建')),
        ],
      ),
    );
  }
}

class _FolderListView extends StatelessWidget {
  final LibraryState library;
  final VoidCallback onNewFolder;
  const _FolderListView({required this.library, required this.onNewFolder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    if (library.bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.folder_off_rounded, size: 48, color: AppTheme.hairStrong(brightness)),
            const SizedBox(height: 16),
            Text('还没有文件夹', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('点击右上角创建第一个文件夹', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onNewFolder,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('新建文件夹'),
            ),
          ]),
        ),
      );
    }

    final folders = [
      _FolderData(name: '未分类', icon: Icons.folder_rounded, count: library.bookmarks.length),
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 32),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.hair(brightness)),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.tint(brightness), borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(folder.icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(folder.name, style: theme.textTheme.titleSmall?.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${folder.count} 篇文章',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.hairStrong(brightness)),
            ]),
          ),
        );
      },
    );
  }
}

class _FolderData {
  final String name;
  final IconData icon;
  final int count;
  const _FolderData({required this.name, required this.icon, required this.count});
}

enum BookmarkFilter { all, readLater }

class _BookmarkList extends ConsumerStatefulWidget {
  final BookmarkFilter filter;
  const _BookmarkList({required this.filter});

  @override
  ConsumerState<_BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends ConsumerState<_BookmarkList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final library = ref.watch(libraryStoreProvider);

    List<Article> items;
    switch (widget.filter) {
      case BookmarkFilter.all:
        items = library.bookmarks;
        break;
      case BookmarkFilter.readLater:
        items = library.bookmarks.where((a) => a.isReadLater).toList();
        break;
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 80),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bookmark_border_rounded, size: 48,
                    color: AppTheme.hairStrong(Theme.of(context).brightness)),
                const SizedBox(height: 14),
                Text('还没有收藏', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('点击文章卡片的收藏按钮，内容会保存在这里',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5)),
              ]),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 6, bottom: 32),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final article = items[index];
          return ArticleCard(
            article: article,
            onTap: () => context.push('/reader/${article.id}'),
          );
        },
      ),
    );
  }
}

class _BookmarkStats extends StatelessWidget {
  final LibraryState library;
  const _BookmarkStats({required this.library});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(top: BorderSide(color: AppTheme.hair(brightness), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '${library.bookmarkCount}', label: '总收藏'),
          Container(width: 1, height: 28, color: AppTheme.hair(brightness)),
          _StatItem(value: '1', label: '文件夹'),
          Container(width: 1, height: 28, color: AppTheme.hair(brightness)),
          _StatItem(value: '${library.readLaterCount}', label: '稍后阅读'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11, fontWeight: FontWeight.w400)),
    ]);
  }
}
