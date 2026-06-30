import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/article_cache.dart';
import '../../../../core/state/library_store.dart';
import '../../../../core/state/reading_stats.dart';
import '../../../feed/domain/entities/article.dart';

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
      ref.read(libraryStoreProvider.notifier).markRead(article.id);
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
            if (!_pageLoaded && mounted) {
              setState(() => _loadFailed = true);
            }
          },
        ),
      )
      ..loadRequest(uri);
    setState(() => _controller = controller);
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
    final brightness = theme.brightness;
    final article = _article;
    final library = ref.watch(libraryStoreProvider);

    if (article == null) {
      return Scaffold(
        appBar: AppBar(
          leading: _IconBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.article_outlined,
                  size: 48, color: AppTheme.hairStrong(brightness)),
              const SizedBox(height: 16),
              Text('文章未加载', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final isBookmarked = library.isBookmarked(article.id);

    return Scaffold(
      body: Column(
        children: [
          // Reader header
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                _IconBtn(
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked ? theme.colorScheme.primary : null,
                  onTap: () =>
                      ref.read(libraryStoreProvider.notifier).toggleBookmark(article),
                ),
                _IconBtn(
                  icon: Icons.share_outlined,
                  onTap: () => Share.share(
                    '${article.title}\n${article.url}',
                    subject: article.title,
                  ),
                ),
                _IconBtn(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showMoreMenu(context, article),
                ),
              ],
            ),
          ),
          // Article meta
          Container(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.hair(brightness), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(_formatTime(article.publishedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w400,
                        )),
                    const SizedBox(width: 12),
                    Icon(Icons.link_rounded,
                        size: 13, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        Uri.tryParse(article.url)?.host ?? article.feedName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Loading progress
          if (_controller != null && !_pageLoaded && !_loadFailed && _loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100,
              minHeight: 2,
              backgroundColor: AppTheme.surface2(brightness),
            ),
          // Content / WebView
          Expanded(child: _buildBody(article)),
        ],
      ),
      floatingActionButton: article.summary != null
          ? FloatingActionButton.extended(
              onPressed: () => _showSummary(context, article),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: Icon(Icons.auto_awesome, size: 17),
              label: const Text('AI 摘要'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(Article article) {
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
              color: Theme.of(context).scaffoldBackgroundColor,
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
                size: 48, color: theme.textTheme.bodySmall?.color),
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

  void _showMoreMenu(BuildContext context, Article article) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('稍后阅读'),
                onTap: () {
                  ref.read(libraryStoreProvider.notifier).toggleReadLater(article);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('在浏览器中打开'),
                onTap: () {
                  _launchUrl(article.url);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
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
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('AI 智能摘要',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppTheme.tint(Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  article.summary ?? '该文章暂无摘要内容。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                '· 摘要来自订阅源提供的文章简介',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
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

  String _formatTime(DateTime? time) {
    if (time == null) return '未知时间';
    final diff = DateTime.now().difference(time);
    if (diff.isNegative || diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${time.month}/${time.day}';
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}
