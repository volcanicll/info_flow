import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/state/article_cache.dart';
import '../../../../core/state/library_store.dart';
import '../../../../core/state/reading_stats.dart';
import '../../../feed/domain/entities/article.dart';

/// 文章阅读器
///
/// 从文章缓存取真实文章，用 WebView 加载原文。
/// 自动标记已读、累计阅读时长、收藏/分享联动全局状态。
class ReaderPage extends ConsumerStatefulWidget {
  final String articleId;

  const ReaderPage({super.key, required this.articleId});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  WebViewController? _controller;
  bool _pageLoaded = false;
  bool _loadFailed = false;
  int _loadingProgress = 0;
  DateTime? _enterTime;

  Article? get _article =>
      ref.watch(articleCacheProvider)[widget.articleId];

  @override
  void initState() {
    super.initState();
    _enterTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setup();
    });
  }

  void _setup() {
    final article = _article;
    if (article != null) {
      // 标记已读
      ref.read(libraryStoreProvider.notifier).markRead(article.id);
      // 初始化 WebView
      _initWebView(article);
    }
  }

  void _initWebView(Article article) {
    final uri = Uri.tryParse(article.url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() => _loadFailed = true);
      return;
    }
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _loadingProgress = p),
          onPageFinished: (_) => setState(() {
            _pageLoaded = true;
            _loadingProgress = 100;
          }),
          onWebResourceError: (e) {
            // 仅当页面从未成功加载过才视为失败，避免子资源错误覆盖正常页面
            if (!_pageLoaded && mounted) {
              setState(() => _loadFailed = true);
            }
          },
        ),
      )
      ..loadRequest(uri);
    setState(() {
      _controller = controller;
    });
  }

  @override
  void dispose() {
    final enterTime = _enterTime;
    if (enterTime != null) {
      final seconds = DateTime.now().difference(enterTime).inSeconds;
      if (seconds > 0) {
        ref.read(readingStatsProvider.notifier).addReadDuration(seconds);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final article = _article;
    final library = ref.watch(libraryStoreProvider);

    // 文章不在缓存中（如深链直入）
    if (article == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.article_outlined,
                    size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('文章未加载', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('请从信息流进入阅读', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    final isBookmarked = library.isBookmarked(article.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(article.feedName,
            style: const TextStyle(fontSize: 16), maxLines: 1,
            overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded),
            color: isBookmarked ? theme.colorScheme.primary : null,
            tooltip: '收藏',
            onPressed: () =>
                ref.read(libraryStoreProvider.notifier).toggleBookmark(article),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享',
            onPressed: () => Share.share(
              '${article.title}\n${article.url}',
              subject: article.title,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'read_later') {
                await ref
                    .read(libraryStoreProvider.notifier)
                    .toggleReadLater(article);
              } else if (value == 'open_browser') {
                _launchUrl(article.url);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'read_later', child: Text('稍后阅读')),
              const PopupMenuItem(
                  value: 'open_browser', child: Text('在浏览器中打开')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 文章元信息条
          _ArticleMetaBar(article: article),
          // 加载进度
          if (_controller != null &&
              !_pageLoaded &&
              !_loadFailed &&
              _loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100,
              minHeight: 2,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          // 正文
          Expanded(child: _buildBody(article)),
        ],
      ),
      floatingActionButton: article.summary != null
          ? FloatingActionButton.extended(
              onPressed: () => _showSummary(context, article),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('AI 摘要'),
            )
          : null,
    );
  }

  Widget _buildBody(Article article) {
    final theme = Theme.of(context);
    if (_loadFailed || article.url.isEmpty) {
      return _buildError(article);
    }
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (!_pageLoaded)
          Positioned.fill(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildError(Article article) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.web_asset_off_rounded,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('无法加载原文', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              article.url.isNotEmpty ? '部分站点限制内嵌访问，可尝试在浏览器打开'
                  : '该文章未提供原文链接',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (article.url.isNotEmpty)
              FilledButton.icon(
                onPressed: () => _launchUrl(article.url),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('在浏览器打开'),
              ),
          ],
        ),
      ),
    );
  }

  void _showSummary(BuildContext context, Article article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('AI 智能摘要',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  article.summary ?? '该文章暂无摘要内容。',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '· 摘要来自订阅源提供的文章简介',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ArticleMetaBar extends StatelessWidget {
  final Article article;
  const _ArticleMetaBar({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border:
            Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 13, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(
                _formatTime(article.publishedAt),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Icon(Icons.link_rounded,
                  size: 13, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  Uri.tryParse(article.url)?.host ?? article.feedName,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '未知时间';
    final diff = DateTime.now().difference(time);
    if (diff.isNegative || diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }
}
