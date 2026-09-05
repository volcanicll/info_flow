import 'package:xml/xml.dart';

/// 一个 OPML outline 条目（RSS/Atom 订阅）。
class OpmlSubscription {
  final String name;
  final String feedUrl;
  final String siteUrl;
  final String category;

  const OpmlSubscription({
    required this.name,
    required this.feedUrl,
    this.siteUrl = '',
    this.category = '',
  });
}

/// OPML 解析器：将 OPML 2.0 文档解析为订阅列表。
///
/// 兼容常见变体：
/// - outline 的 xmlUrl 为订阅地址，htmlUrl 为站点首页
/// - 标题优先取 title，回退到 text 属性
/// - type 缺失或为 rss/atom 均接受
class OpmlParser {
  OpmlParser._();

  static List<OpmlSubscription> parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final outlines = document.findAllElements('outline');
    final result = <OpmlSubscription>[];
    for (final node in outlines) {
      final xmlUrl = node.getAttribute('xmlUrl');
      if (xmlUrl == null || xmlUrl.trim().isEmpty) continue;
      final name = (node.getAttribute('title') ?? node.getAttribute('text') ?? '')
          .trim();
      final siteUrl = node.getAttribute('htmlUrl') ?? '';
      final category = node.getAttribute('category') ?? '';
      result.add(OpmlSubscription(
        name: name.isEmpty ? siteUrl : name,
        feedUrl: xmlUrl.trim(),
        siteUrl: siteUrl,
        category: category,
      ));
    }
    return result;
  }
}

/// OPML 生成器：将订阅列表导出为 OPML 2.0 文档。
class OpmlBuilder {
  OpmlBuilder._();

  static String build({
    required String title,
    required List<OpmlSubscription> subscriptions,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<opml version="2.0">');
    buffer.writeln('  <head>');
    buffer.writeln('    <title>${_escape(title)}</title>');
    buffer.writeln('  </head>');
    buffer.writeln('  <body>');
    for (final sub in subscriptions) {
      buffer.writeln(_outline(sub));
    }
    buffer.writeln('  </body>');
    buffer.writeln('</opml>');
    return buffer.toString();
  }

  static String _outline(OpmlSubscription sub) {
    final attrs = StringBuffer('type="rss"');
    attrs.write(' text="${_escape(sub.name)}"');
    attrs.write(' title="${_escape(sub.name)}"');
    if (sub.siteUrl.isNotEmpty) {
      attrs.write(' htmlUrl="${_escape(sub.siteUrl)}"');
    }
    attrs.write(' xmlUrl="${_escape(sub.feedUrl)}"');
    return '    <outline $attrs/>';
  }

  static String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
