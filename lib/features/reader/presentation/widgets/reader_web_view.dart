import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../feed/domain/entities/article.dart';

/// 网页原文视图：内嵌 WebView，加载失败时给出浏览器打开兜底。
class ReaderWebView extends StatelessWidget {
  final Article article;
  final WebViewController? controller;
  final bool pageLoaded;
  final bool loadFailed;
  final Color background;

  const ReaderWebView({
    super.key,
    required this.article,
    required this.controller,
    required this.pageLoaded,
    required this.loadFailed,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    if (loadFailed || article.url.isEmpty) {
      return EmptyState(
        icon: Icons.web_asset_off_rounded,
        title: '无法加载原文',
        description: article.url.isNotEmpty
            ? '部分站点限制内嵌访问，可尝试在浏览器打开'
            : '该文章未提供原文链接',
        actionLabel: article.url.isNotEmpty ? '在浏览器打开' : null,
        onAction: article.url.isNotEmpty ? () => _launchUrl(article.url) : null,
      );
    }
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        WebViewWidget(controller: controller!),
        if (!pageLoaded)
          Positioned.fill(
            child: Container(
              color: background,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
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
