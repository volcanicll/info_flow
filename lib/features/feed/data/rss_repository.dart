import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

import '../../../core/utils/news_normalizer.dart';
import '../domain/entities/article.dart';
import 'rss_sources.dart';

class RssRepository {
  RssRepository(this._dio);

  final Dio _dio;
  int failedCount = 0;

  Future<List<Article>> fetchSource(RssSource source,
      {int? maxItems}) async {
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

      final articles = _parse(body, source);
      if (maxItems != null && articles.length > maxItems) {
        return articles.take(maxItems).toList();
      }
      return articles;
    } catch (_) {
      failedCount++;
      return [];
    }
  }

  Future<List<Article>> fetchSources(List<RssSource> sources,
      {int? maxItems}) async {
    if (sources.isEmpty) return [];
    failedCount = 0;
    final results = await Future.wait(
        sources.map((s) => fetchSource(s, maxItems: maxItems)));
    return _merge(results);
  }

  List<Article> _merge(List<List<Article>> results) {
    final merged = <Article>[];
    for (final list in results) {
      merged.addAll(list);
    }
    final deduped = NewsNormalizer.dedupe(merged);
    deduped.sort((a, b) {
      final ta = a.publishedAt ?? DateTime(2000);
      final tb = b.publishedAt ?? DateTime(2000);
      return tb.compareTo(ta);
    });
    return deduped;
  }

  List<Article> _parse(String xmlString, RssSource source) {
    final document = XmlDocument.parse(xmlString);
    final articles = <Article>[];

    final rssItems = document.findAllElements('item');
    if (rssItems.isNotEmpty) {
      for (final item in rssItems) {
        articles.add(_fromRssItem(item, source));
      }
      return articles;
    }

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
    final cover =
        _extractFirstImage(contentStr.isNotEmpty ? contentStr : summary);

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

class HttpDateParser {
  static final _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  static DateTime? parseRfc822(String input) {
    final parts = input.trim().split(RegExp(r'[\s,]+'));
    if (parts.length < 6) return null;
    try {
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
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 12),
  ));
  return RssRepository(dio);
});
