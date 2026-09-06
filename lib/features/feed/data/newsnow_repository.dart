import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../signal_hub/data/ticker_dictionary.dart';
import '../../signal_hub/domain/entities/ticker_ref.dart';
import '../../../../core/network/api_client.dart';
import '../domain/entities/article.dart';

/// NewsNow 公共实例快讯源（开源项目 ourongxing/newsnow 的聚合接口，
/// 免鉴权、服务端缓存约 30 分钟）。单源失败静默降级，不影响其余源。
///
/// 上游各源字段不统一：
/// - cls/wallstreetcn 标题含未转义控制字符与原始换行，需清洗后 jsonDecode；
/// - 日期位置三种：`pubDate`(ms) / `extra.date`(ms) / `date`(ISO 或 ms)；
/// - 微博/知乎热榜条目无日期，按榜单排名序展示。
class NewsNowRepository {
  final Dio _dio;

  NewsNowRepository(this._dio);

  static const _baseUrl = 'https://newsnow.busiyi.world/api/s';

  /// 情报页「热榜」快讯源：中文财经实时快讯。
  static const List<({String id, String name, int color})> flashSources = [
    (id: 'cls', name: '财联社快讯', color: 0xFFB03A2E),
    (id: 'wallstreetcn', name: '华尔街见闻', color: 0xFF57534E),
    (id: 'jin10', name: '金十数据', color: 0xFFB7791F),
    (id: 'fastbull', name: 'FastBull 快讯', color: 0xFF1E7F5C),
  ];

  /// 破圈雷达监控的大众热榜。
  static const List<({String id, String name})> mainstreamSources = [
    (id: 'weibo', name: '微博'),
    (id: 'zhihu', name: '知乎'),
    (id: 'toutiao', name: '头条'),
  ];

  /// 快讯流：并行抓取全部快讯源，按时间降序合并。
  Future<List<Article>> fetchFlashes() async {
    final results = await Future.wait(flashSources.map((s) async {
      try {
        final resp = await _dio.get<String>(_baseUrl, queryParameters: {'id': s.id});
        final body = resp.data ?? '';
        return parsePayload(s.id, s.name, s.color, body);
      } catch (_) {
        return <Article>[];
      }
    }));
    final all = results.expand((a) => a).toList()
      ..sort((a, b) => (b.publishedAt ?? DateTime(2000))
          .compareTo(a.publishedAt ?? DateTime(2000)));
    return all;
  }

  /// 破圈雷达：大众热榜标题命中 Web3 关键词的条目（保持榜单排名序）。
  Future<List<BreakoutHit>> fetchBreakoutHits() async {
    final perSource = await Future.wait(mainstreamSources.map((s) async {
      try {
        final resp = await _dio.get<String>(_baseUrl, queryParameters: {'id': s.id});
        final body = resp.data ?? '';
        return parsePayload(s.id, s.name, 0xFF57534E, body);
      } catch (_) {
        return <Article>[];
      }
    }));
    final hits = <BreakoutHit>[];
    for (var i = 0; i < mainstreamSources.length; i++) {
      final platform = mainstreamSources[i].name;
      var taken = 0;
      for (final article in perSource[i]) {
        final keyword = matchBreakoutKeyword(article.title);
        if (keyword == null) continue;
        hits.add(BreakoutHit(article: article, keyword: keyword, platform: platform));
        if (++taken >= 3) break; // 每平台最多 3 条，避免单源刷屏
      }
    }
    return hits;
  }

  /// 清洗上游未转义控制字符后解析（cls 实测标题含原始换行，字符串内
  /// 的 LF/Tab 对严格 jsonDecode 同样非法；结构位置的空白可安全移除）。
  List<Article> parsePayload(String id, String name, int color, String body) {
    final sanitized = body.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    final dynamic decoded;
    try {
      decoded = jsonDecode(sanitized);
    } catch (_) {
      return const [];
    }
    final items = decoded is Map ? decoded['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((j) => _articleFromItem(id, name, color, j))
        .where((a) => a.title.isNotEmpty)
        .toList();
  }

  Article _articleFromItem(
      String id, String name, int color, Map<String, dynamic> j) {
    final title = (j['title'] ?? j['id'] ?? '').toString().trim();
    final url = (j['url'] ?? j['mobileUrl'] ?? '').toString();
    return Article(
      id: 'newsnow-$id-${j['id'] ?? title.hashCode}',
      feedId: 'newsnow-$id',
      feedName: name,
      feedColor: color,
      title: title,
      url: url,
      // 快讯没有正文：标题即全文，ticker 词典据此标注徽章
      content: title,
      publishedAt: _dateFrom(j),
    );
  }

  DateTime? _dateFrom(Map<String, dynamic> j) {
    final pub = j['pubDate'];
    if (pub is num) return _fromMs(pub);
    final extra = j['extra'];
    if (extra is Map) {
      final d = extra['date'];
      if (d is num) return _fromMs(d);
    }
    final date = j['date'];
    if (date is num) return _fromMs(date);
    if (date is String) return DateTime.tryParse(date)?.toLocal();
    return null;
  }

  DateTime _fromMs(num ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true).toLocal();
}

/// 破圈命中：大众热榜条目 + 命中的关键词 + 来源平台。
class BreakoutHit {
  final Article article;
  final String keyword;
  final String platform;

  const BreakoutHit({
    required this.article,
    required this.keyword,
    required this.platform,
  });
}

/// 破圈关键词命中判断。行业通用词子串匹配；拉丁短别名（sol/bnb 等）
/// 用词边界匹配，避免 solar/assume 这类误报。
String? matchBreakoutKeyword(String rawTitle) {
  final title = rawTitle.toLowerCase();
  if (title.isEmpty) return null;
  for (final kw in industryKeywords) {
    if (title.contains(kw)) return kw;
  }
  final dict = TickerDictionary.instance;
  for (final e in dict.entries) {
    if (e.asset != AssetClass.crypto) continue;
    final candidates = [e.symbol.toLowerCase(), ...e.aliases];
    for (final alias in candidates) {
      if (_containsKeyword(title, alias)) return e.symbol;
    }
  }
  return null;
}

/// 加密行业通用词（小写）。比特币/以太坊等主流币不在列：
/// 它们由 ticker 词典的中文别名覆盖，命中后返回标准符号。
const industryKeywords = [
  '加密货币', '稳定币', '数字货币', '虚拟货币', '区块链', 'web3',
  '链上', '代币', '加密市场', '加密交易所', '挖矿',
];

bool _containsKeyword(String lowerTitle, String alias) {
  final isLatin = alias.runes.every((r) => r < 128);
  if (isLatin && alias.length <= 4) {
    return RegExp('\\b${RegExp.escape(alias)}\\b').hasMatch(lowerTitle);
  }
  return lowerTitle.contains(alias);
}

final newsNowRepositoryProvider =
    Provider<NewsNowRepository>((ref) => NewsNowRepository(ref.watch(dioProvider)));

/// 终端首页破圈信号。autoDispose：离开首页即释放，回首页重扫
/// （上游缓存约 30 分钟，重复扫描成本可忽略）。
final breakoutRadarProvider =
    FutureProvider.autoDispose<List<BreakoutHit>>((ref) async {
  return ref.watch(newsNowRepositoryProvider).fetchBreakoutHits();
});
