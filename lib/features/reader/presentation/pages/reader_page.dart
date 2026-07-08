import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/article_cache.dart';
import '../../../../core/state/library_store.dart';
import '../../../../core/state/reading_stats.dart';
import '../../../../shared/widgets/press_scale.dart';
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

  // Reader mode
  bool _isNativeMode = true;

  // Scroll-linked reading progress
  final ScrollController _readingScrollController = ScrollController();
  double _readingProgress = 0;

  // Reading settings
  double _fontSize = 16;
  double _lineHeight = 1.65;
  int _bgColorIndex = 0;

  static const _bgColors = [
    Colors.white,
    Color(0xFFFAF6EE), // warm
    Color(0xFFF0F7F0), // green
    Color(0xFF282838), // dark
    Color(0xFF1A1A1A), // black
  ];

  Article? get _article =>
      ref.watch(articleCacheProvider)[widget.articleId];

  @override
  void initState() {
    super.initState();
    _enterTime = DateTime.now();
    _readingScrollController.addListener(_onReadingScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setup();
    });
  }

  void _onReadingScroll() {
    if (!_readingScrollController.hasClients) return;
    final pos = _readingScrollController.position;
    if (pos.maxScrollExtent <= 0) {
      setState(() => _readingProgress = 1.0);
      return;
    }
    final progress = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    if ((_readingProgress - progress).abs() > 0.005) {
      setState(() => _readingProgress = progress);
    }
  }

  void _setup() {
    final article = _article;
    if (article != null) {
      ref.read(libraryStoreProvider.notifier).markRead(article.id);
      if (!_isNativeMode) _initWebView(article);
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
    _readingScrollController.removeListener(_onReadingScroll);
    _readingScrollController.dispose();
    final enterTime = _enterTime;
    if (enterTime != null) {
      final seconds = DateTime.now().difference(enterTime).inSeconds;
      if (seconds > 0) {
        ref.read(readingStatsProvider.notifier).addReadDuration(seconds);
      }
    }
    super.dispose();
  }

  Color get _currentBgColor => _bgColors[_bgColorIndex];
  bool get _isDarkBg => _bgColorIndex >= 3;

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
              Icon(Icons.article_outlined, size: 48, color: AppTheme.hairStrong(brightness)),
              const SizedBox(height: 16),
              Text('文章未加载', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final isBookmarked = library.isBookmarked(article.id);

    return Scaffold(
      backgroundColor: _currentBgColor,
      body: Column(
        children: [
          // Reading progress bar (scroll-linked)
          if (_isNativeMode)
            LinearProgressIndicator(
              value: _readingProgress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          // Header
          Container(
            color: _currentBgColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                    color: _isDarkBg ? Colors.white : null,
                  ),
                  const Spacer(),
                  _IconBtn(
                    icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked ? theme.colorScheme.primary : (_isDarkBg ? Colors.white : null),
                    onTap: () => ref.read(libraryStoreProvider.notifier).toggleBookmark(article),
                  ),
                  _IconBtn(
                    icon: Icons.share_outlined,
                    color: _isDarkBg ? Colors.white : null,
                    onTap: () => Share.share('${article.title}\n${article.url}', subject: article.title),
                  ),
                  _IconBtn(
                    icon: Icons.more_horiz_rounded,
                    color: _isDarkBg ? Colors.white : null,
                    onTap: () => _showMoreMenu(context, article),
                  ),
                ],
              ),
            ),
          ),
          // Article meta
          Container(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            color: _currentBgColor,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _isDarkBg ? Colors.white.withValues(alpha: 0.1) : AppTheme.hair(brightness),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, height: 1.35, letterSpacing: -0.3,
                    color: _isDarkBg ? Colors.white : theme.textTheme.headlineMedium?.color,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13,
                        color: _isDarkBg ? Colors.white54 : theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(_formatTime(article.publishedAt),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
                            color: _isDarkBg ? Colors.white54 : theme.textTheme.bodySmall?.color)),
                    const SizedBox(width: 12),
                    Icon(Icons.link_rounded, size: 13,
                        color: _isDarkBg ? Colors.white54 : theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        Uri.tryParse(article.url)?.host ?? article.feedName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
                            color: _isDarkBg ? Colors.white54 : theme.textTheme.bodySmall?.color),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '预计 ${_estimateReadTime(article)} 分钟',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
                          color: _isDarkBg ? Colors.white54 : theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mode toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: _currentBgColor,
            child: Row(
              children: [
                _ModeToggle(
                  isActive: _isNativeMode, label: '阅读模式',
                  onTap: () => setState(() => _isNativeMode = true),
                  textColor: _isDarkBg ? Colors.white : null,
                ),
                const SizedBox(width: 8),
                _ModeToggle(
                  isActive: !_isNativeMode, label: '网页原文',
                  onTap: () {
                    setState(() => _isNativeMode = false);
                    if (_controller == null) _initWebView(article);
                  },
                  textColor: _isDarkBg ? Colors.white : null,
                ),
                const Spacer(),
                _IconBtn(
                  icon: Icons.text_fields_rounded, size: 18,
                  color: _isDarkBg ? Colors.white54 : theme.textTheme.bodySmall?.color,
                  onTap: () => _showReadingSettings(context),
                ),
              ],
            ),
          ),
          // WebView loading
          if (!_isNativeMode && _controller != null && !_pageLoaded && !_loadFailed && _loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100, minHeight: 2,
              backgroundColor: AppTheme.surface2(brightness),
            ),
          // Content
          Expanded(
            child: _isNativeMode ? _buildNativeContent(article) : _buildWebViewContent(article),
          ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _currentBgColor,
          border: Border(
            top: BorderSide(
              color: _isDarkBg ? Colors.white.withValues(alpha: 0.1) : AppTheme.hair(brightness),
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.paddingOf(context).bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomAction(icon: Icons.favorite_border_rounded, label: '点赞',
                color: _isDarkBg ? Colors.white70 : null),
            _BottomAction(icon: Icons.chat_bubble_outline_rounded, label: '评论',
                color: _isDarkBg ? Colors.white70 : null),
            _BottomAction(icon: Icons.share_outlined, label: '分享',
                color: _isDarkBg ? Colors.white70 : null,
                onTap: () => Share.share('${article.title}\n${article.url}', subject: article.title)),
            _BottomAction(
              icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              label: '收藏',
              color: isBookmarked ? theme.colorScheme.primary : (_isDarkBg ? Colors.white70 : null),
              onTap: () => ref.read(libraryStoreProvider.notifier).toggleBookmark(article),
            ),
          ],
        ),
      ),
      floatingActionButton: article.summary != null
          ? FloatingActionButton.extended(
              onPressed: () => _showSummary(context, article),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: const Icon(Icons.auto_awesome, size: 17),
              label: const Text('AI 摘要'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            )
          : null,
    );
  }

  Widget _buildNativeContent(Article article) {
    final theme = Theme.of(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (_) { _onReadingScroll(); return false; },
      child: SingleChildScrollView(
        controller: _readingScrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.coverImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  article.coverImageUrl!,
                  width: double.infinity, height: 200, fit: BoxFit.cover,
                  frameBuilder: (ctx, child, frame, wasSyncLoaded) =>
                      AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  ),
                  errorBuilder: (_, __, ___) => Container(
                    height: 200, color: AppTheme.surface2(theme.brightness),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // AI Summary
            if (article.summary != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppTheme.tint(theme.brightness),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('AI 摘要', style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                    ]),
                    const SizedBox(height: 10),
                    Text(article.summary!, style: TextStyle(
                      fontSize: 14, height: 1.65,
                      color: _isDarkBg ? Colors.white70 : theme.textTheme.bodyMedium?.color,
                    )),
                    const SizedBox(height: 8),
                    Text('· 摘要来自订阅源提供的文章简介', style: TextStyle(
                      fontSize: 11,
                      color: _isDarkBg ? Colors.white38 : theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w400,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Body
            Text(
              article.content ?? article.summary ?? '暂无正文内容',
              style: TextStyle(
                fontSize: _fontSize, height: _lineHeight,
                color: _isDarkBg ? Colors.white.withValues(alpha: 0.88) : theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (article.sentiment != null) ...[
              const SizedBox(height: 24),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _ReaderTag(label: article.feedName),
                _ReaderTag(label: article.sentiment!),
              ]),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewContent(Article article) {
    if (_loadFailed || article.url.isEmpty) return _buildError(article);
    if (_controller == null) return const Center(child: CircularProgressIndicator());
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
            Icon(Icons.web_asset_off_rounded, size: 48, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text('无法加载原文', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              article.url.isNotEmpty ? '部分站点限制内嵌访问，可尝试在浏览器打开' : '该文章未提供原文链接',
              textAlign: TextAlign.center, style: theme.textTheme.bodyMedium,
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

  void _showReadingSettings(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 1,
                decoration: BoxDecoration(
                  color: AppTheme.hairStrong(theme.brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
              const SizedBox(height: 16),
              Text('阅读设置', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              Row(children: [
                Text('字号', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text('${_fontSize.round()} pt', style: theme.textTheme.bodySmall),
              ]),
              Slider(
                value: _fontSize, min: 12, max: 24, divisions: 6,
                onChanged: (v) => setSheetState(() => _fontSize = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text('行高', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(_lineHeight.toStringAsFixed(2), style: theme.textTheme.bodySmall),
              ]),
              Slider(
                value: _lineHeight, min: 1.3, max: 2.0, divisions: 7,
                onChanged: (v) => setSheetState(() => _lineHeight = v),
              ),
              const SizedBox(height: 12),
              Text('背景色', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_bgColors.length, (i) {
                  final selected = _bgColorIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => _bgColorIndex = i);
                      setState(() {});
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _bgColors[i], shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? theme.colorScheme.primary : AppTheme.hair(theme.brightness),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: selected
                          ? Icon(Icons.check_rounded, size: 18,
                              color: i >= 3 ? Colors.white : theme.colorScheme.primary)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, Article article) {
    showModalBottomSheet(
      context: context, showDragHandle: true,
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
                onTap: () { _launchUrl(article.url); Navigator.pop(ctx); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummary(BuildContext context, Article article) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('AI 智能摘要', style: Theme.of(context).textTheme.titleLarge),
              ]),
              const SizedBox(height: 16),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppTheme.tint(Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  article.summary ?? '该文章暂无摘要内容。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65, fontSize: 14),
                ),
              ),
              const SizedBox(height: 11),
              Text('· 摘要来自订阅源提供的文章简介',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  int _estimateReadTime(Article article) {
    final text = article.content ?? article.summary ?? '';
    return (text.length / 400).ceil().clamp(1, 30);
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

// ─── Sub-Components ───────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, this.color, this.size = 22, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: size, color: color)),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isActive;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  const _ModeToggle({required this.isActive, required this.label, required this.onTap, this.textColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressScale(
      pressedScale: 0.94,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : AppTheme.hair(theme.brightness),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isActive ? theme.colorScheme.onPrimary : (textColor ?? theme.textTheme.bodySmall?.color),
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  const _BottomAction({required this.icon, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return PressScale(
      pressedScale: 0.88,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, color: c)),
        ],
      ),
    );
  }
}

class _ReaderTag extends StatelessWidget {
  final String label;
  const _ReaderTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.tint(theme.brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.primary,
      )),
    );
  }
}
