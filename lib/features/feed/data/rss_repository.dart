import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

import '../domain/entities/article.dart';
import 'rss_sources.dart';

/// RSS/Atom 抓取与解析仓库
///
/// 直接从真实 RSS/Atom 源拉取数据，用 xml 库解析为 Article 实体。
/// 不依赖第三方 RSS 库（避免 intl 版本冲突），兼容 RSS 2.0 与 Atom。
/// 单源解析失败 / 超时 / 无网络时静默跳过，保证整体信息流可用。
class RssRepository {
  RssRepository(this._dio);

  final Dio _dio;

  /// 抓取单个源的全部条目
  Future<List<Article>> fetchSource(RssSource source) async {
    try {
      final resp = await _dio.get<String>(
        source.feedUrl,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 12),
          headers: {
            'Accept':
                'application/rss+xml, application/atom+xml, application/xml, text/xml, */*',
            'User-Agent':
                'Mozilla/5.0 (compatible; InfoFlow/1.0; +https://infoflow.app)',
          },
        ),
      );

      final body = resp.data;
      if (body == null || body.trim().isEmpty) return [];

      return _parse(body, source);
    } catch (_) {
      return [];
    }
  }

  /// 并发抓取多个源，去重合并后按时间倒序返回
  Future<List<Article>> fetchSources(List<RssSource> sources) async {
    if (sources.isEmpty) return [];
    final results = await Future.wait(sources.map(fetchSource));
    final merged = <Article>[];
    final seenUrls = <String>{};
    for (final list in results) {
      for (final a in list) {
        final key = a.url.isEmpty ? a.title : a.url;
        if (seenUrls.add(key)) merged.add(a);
      }
    }
    merged.sort((a, b) {
      final ta = a.publishedAt ?? DateTime(2000);
      final tb = b.publishedAt ?? DateTime(2000);
      return tb.compareTo(ta);
    });
    return merged;
  }

  /// 解析 RSS 2.0 或 Atom XML
  List<Article> _parse(String xmlString, RssSource source) {
    final document = XmlDocument.parse(xmlString);
    final articles = <Article>[];

    // RSS 2.0: rss > channel > item
    final rssItems = document.findAllElements('item');
    if (rssItems.isNotEmpty) {
      for (final item in rssItems) {
        articles.add(_fromRssItem(item, source));
      }
      return articles;
    }

    // Atom: feed > entry
    final atomEntries = document.findAllElements('entry');
    for (final entry in atomEntries) {
      articles.add(_fromAtomEntry(entry, source));
    }
    return articles;
  }

  Article _fromRssItem(XmlElement item, RssSource source) {
    final title = _text(item, 'title');
    final link = _text(item, 'link');
    final description = _text(item, 'description');
    final pubDateStr = _text(item, 'pubDate');
    // content:encoded
    final contentEncoded = item
        .findAllElements('encoded')
        .map((e) => e.innerText)
        .firstOrNull;

    final summary = _stripHtml(description);
    final content = _stripHtml(contentEncoded ?? description);
    final cover = _extractFirstImage(contentEncoded ?? description);

    return Article(
      id: '${source.id}_${link.isNotEmpty ? link : title}'.hashCode.toString(),
      feedId: source.id,
      feedName: source.name,
      feedIconUrl: source.faviconUrl,
      feedColor: source.color.toARGB32(),
      title: title.isEmpty ? '（无标题）' : title,
      url: link,
      content: content,
      summary: _truncate(summary),
      coverImageUrl: cover,
      publishedAt: _parseDate(pubDateStr),
    );
  }

  Article _fromAtomEntry(XmlElement entry, RssSource source) {
    final title = _text(entry, 'title');
    // Atom 的 link 取 rel=alternate 或第一个 link 的 href
    String link = '';
    final links = entry.findElements('link');
    for (final l in links) {
      final rel = l.getAttribute('rel');
      if (rel == null || rel == 'alternate') {
        link = l.getAttribute('href') ?? '';
        if (link.isNotEmpty) break;
      }
    }
    final summary = _text(entry, 'summary');
    final contentStr = _text(entry, 'content');
    final pubDateStr = _text(entry, 'published').isNotEmpty
        ? _text(entry, 'published')
        : _text(entry, 'updated');

    final plain = _stripHtml(contentStr.isNotEmpty ? contentStr : summary);
    final cover = _extractFirstImage(contentStr.isNotEmpty ? contentStr : summary);

    return Article(
      id: '${source.id}_${link.isNotEmpty ? link : title}'.hashCode.toString(),
      feedId: source.id,
      feedName: source.name,
      feedIconUrl: source.faviconUrl,
      feedColor: source.color.toARGB32(),
      title: title.isEmpty ? '（无标题）' : title,
      url: link,
      content: plain,
      summary: _truncate(_stripHtml(summary)),
      coverImageUrl: cover,
      publishedAt: _parseDate(pubDateStr),
    );
  }

  String _text(XmlElement parent, String name) {
    final el = parent.findElements(name).firstOrNull;
    return el?.innerText.trim() ?? '';
  }

  String? _stripHtml(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = html_parser.parse(raw);
    final text = parsed.body?.text.trim();
    if (text == null || text.isEmpty) return null;
    // 压缩多余空白
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _truncate(String? text) {
    if (text == null || text.isEmpty) return null;
    if (text.length <= 140) return text;
    return '${text.substring(0, 140)}…';
  }

  String? _extractFirstImage(String? html) {
    if (html == null || html.isEmpty) return null;
    final parsed = html_parser.parse(html);
    final img = parsed.querySelector('img');
    final src = img?.attributes['src'];
    if (src == null || src.isEmpty) return null;
    if (src.startsWith('//')) return 'https:$src';
    return src;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    // RFC822 (RSS): "Wed, 02 Oct 2024 10:30:00 +0800"
    try {
      return HttpDateParser.parseRfc822(raw) ?? DateTime.parse(raw);
    } catch (_) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }
  }
}

/// 简易 RFC822 日期解析，避免依赖 intl
class HttpDateParser {
  static final _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  static DateTime? parseRfc822(String input) {
    // "Wed, 02 Oct 2024 10:30:00 +0800"
    final parts = input.trim().split(RegExp(r'[\s,]+'));
    if (parts.length < 6) return null;
    try {
      // 去掉可能的星期前缀
      int i = 0;
      if (parts[0].length > 2 && int.tryParse(parts[0]) == null) i = 1;
      final day = int.parse(parts[i]);
      final month = _months[parts[i + 1]];
      if (month == null) return null;
      final year = int.parse(parts[i + 2]);
      final time = parts[i + 3].split(':');
      final hour = int.parse(time[0]);
      final minute = int.parse(time[1]);
      final second = time.length > 2 ? int.parse(time[2]) : 0;
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
}

final rssRepositoryProvider = Provider<RssRepository>((ref) {
  // 使用独立的无拦截器 Dio，避免全局 baseUrl / auth 干扰 RSS 抓取
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 12),
  ));
  return RssRepository(dio);
});
