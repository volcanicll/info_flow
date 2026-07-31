import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/article_cache.dart';
import '../../../../core/state/library_store.dart';
import '../../../../core/state/reading_stats.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../feed/domain/entities/article.dart';
import '../controllers/reader_controller.dart';
import '../widgets/reader_native_view.dart';
import '../widgets/reader_toolbar.dart';
import '../widgets/reader_web_view.dart';

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
  DateTime? _enterTime;

  final ScrollController _scrollController = ScrollController();

  Article? get _article => ref.read(articleCacheProvider)[widget.articleId];

  @override
  void initState() {
    super.initState();
    _enterTime = DateTime.now();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final article = _article;
      if (article != null) {
        ref.read(libraryStoreProvider.notifier).markRead(article.id);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final progress =
        pos.maxScrollExtent <= 0 ? 1.0 : pos.pixels / pos.maxScrollExtent;
    ref.read(readerControllerProvider.notifier).setProgress(progress);
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
          onPageFinished: (_) => setState(() => _pageLoaded = true),
          onWebResourceError: (e) {
            if (!_pageLoaded && mounted) setState(() => _loadFailed = true);
          },
        ),
      )
      ..loadRequest(uri);
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
    final article = ref.watch(articleCacheProvider)[widget.articleId];
    final state = ref.watch(readerControllerProvider);
    final ctrl = ref.read(readerControllerProvider.notifier);
    final paper = readerPaperTones[state.paperIndex];

    if (article == null) {
      return Scaffold(
        appBar: AppBar(
          leading: ReaderIconBtn(
            icon: Icons.arrow_back_rounded,
            color: context.colors.ink,
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: const EmptyState(
          icon: Icons.article_outlined,
          title: '文章未加载',
          description: '返回信息流重新进入',
        ),
      );
    }

    return Scaffold(
      backgroundColor: paper.background,
      body: Column(
        children: [
          if (state.isNativeMode)
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(context.colors.accent),
            ),
          _Header(article: article, paper: paper),
          _ModeBar(
            article: article,
            state: state,
            paper: paper,
            onNative: () => ctrl.setNativeMode(true),
            onWeb: () {
              ctrl.setNativeMode(false);
              if (_controller == null) _initWebView(article);
            },
            onSettings: () => showReadingSettings(context, ref),
          ),
          Expanded(
            child: state.isNativeMode
                ? ReaderNativeView(
                    article: article,
                    paper: paper,
                    fontSize: state.fontSize,
                    lineHeight: state.lineHeight,
                    scrollController: _scrollController,
                  )
                : ReaderWebView(
                    article: article,
                    controller: _controller,
                    pageLoaded: _pageLoaded,
                    loadFailed: _loadFailed,
                    background: paper.background,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: ReaderBottomBar(article: article, paper: paper),
    );
  }
}

/// 顶栏：返回 + 分享 + 更多。
class _Header extends ConsumerWidget {
  final Article article;
  final ReaderPaper paper;
  const _Header({required this.article, required this.paper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          ReaderIconBtn(
            icon: Icons.arrow_back_rounded,
            color: paper.ink,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          ReaderIconBtn(
            icon: Icons.ios_share_rounded,
            color: paper.ink,
            size: 20,
            onTap: () => Share.share('${article.title}\n${article.url}',
                subject: article.title),
          ),
          ReaderIconBtn(
            icon: Icons.more_horiz_rounded,
            color: paper.ink,
            onTap: () => _showMoreMenu(context, ref, article),
          ),
        ],
      ),
    );
  }
}

/// 模式切换栏：阅读模式 / 网页原文 + 排版设置。
class _ModeBar extends StatelessWidget {
  final Article article;
  final ReaderViewState state;
  final ReaderPaper paper;
  final VoidCallback onNative;
  final VoidCallback onWeb;
  final VoidCallback onSettings;

  const _ModeBar({
    required this.article,
    required this.state,
    required this.paper,
    required this.onNative,
    required this.onWeb,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 16, 10),
      child: Row(
        children: [
          ReaderModeToggle(
            isActive: state.isNativeMode,
            label: '阅读模式',
            ink: paper.ink,
            inkSecondary: paper.inkSecondary,
            accent: c.accent,
            onTap: onNative,
          ),
          const SizedBox(width: 22),
          ReaderModeToggle(
            isActive: !state.isNativeMode,
            label: '网页原文',
            ink: paper.ink,
            inkSecondary: paper.inkSecondary,
            accent: c.accent,
            onTap: onWeb,
          ),
          const Spacer(),
          ReaderIconBtn(
            icon: Icons.text_fields_rounded,
            color: paper.inkSecondary,
            size: 20,
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

void _showMoreMenu(BuildContext context, WidgetRef ref, Article article) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.paper,
    builder: (ctx) => SafeArea(
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
          const SizedBox(height: 12),
        ],
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
