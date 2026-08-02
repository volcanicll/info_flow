import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/ai_config.dart';
import '../../../core/state/article_cache.dart';
import '../../../features/feed/data/rss_sources.dart';
import '../../../features/feed/domain/entities/article.dart';
import '../../../features/market/data/fear_greed_repository.dart';
import '../../../features/market/data/market_repository.dart';
import '../../../features/market/domain/models/fear_greed_index.dart';
import '../../../features/market/domain/models/market_quote.dart';
import '../../../features/precious_metals/data/metals_repository.dart';
import '../../../features/precious_metals/domain/models/metal_price.dart';

class AiService {
  AiService(this._ref);
  final Ref _ref;

  Future<String> reply(String userMessage) async {
    if (RegExp(r'每日播报|日报|daily\s*brief').hasMatch(userMessage.trim())) {
      return dailyBrief();
    }
    final config = _ref.read(aiConfigProvider);
    if (config.apiKey.trim().isNotEmpty) {
      try {
        return await _callLlm(userMessage, config);
      } catch (_) {
        return _localReply(userMessage);
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return _localReply(userMessage);
  }

  /// 每日播报：聚合市场数据（恐惧贪婪 / 加密 / 贵金属）与今日要闻，
  /// 生成一份类 TechDaily 的日报。配置 LLM 时走真实模型，否则本地规则。
  Future<String> dailyBrief() async {
    final config = _ref.read(aiConfigProvider);
    if (config.apiKey.trim().isNotEmpty) {
      try {
        return await _callLlm('请生成今天的每日播报', config);
      } catch (_) {
        return _localDailyBrief(await _fetchMarketSnapshot());
      }
    }
    return _localDailyBrief(await _fetchMarketSnapshot());
  }

  /// 并行拉取市场快照；任一源失败不影响其它（静默降级为 null）。
  Future<({FearGreedIndex? fng, List<MarketQuote> crypto, List<MetalPrice> metals})>
      _fetchMarketSnapshot() async {
    final fearRepo = _ref.read(fearGreedRepositoryProvider);
    final marketRepo = _ref.read(marketRepositoryProvider);
    final metalsRepo = _ref.read(metalsRepositoryProvider);

    final results = await Future.wait([
      fearRepo.fetchIndex(),
      marketRepo.fetchCryptoQuotes(['BTC', 'ETH', 'SOL', 'BNB']),
      metalsRepo.fetchPrices(),
    ]);

    return (
      fng: results[0] as FearGreedIndex?,
      crypto: results[1] as List<MarketQuote>,
      metals: results[2] as List<MetalPrice>,
    );
  }

  String _localDailyBrief(
    ({FearGreedIndex? fng, List<MarketQuote> crypto, List<MetalPrice> metals})
        market,
  ) {
    final cache = _ref.read(articleCacheProvider);
    final articles = cache.values.toList();
    final buf = StringBuffer();

    buf.writeln('📰 **每日播报**');
    buf.writeln();

    // ── 市场情绪 ──
    final fng = market.fng;
    if (fng != null) {
      buf.writeln('**市场情绪**：${fng.classification}（${fng.value}/100）');
    }

    // ── 加密行情 ──
    if (market.crypto.isNotEmpty) {
      buf.writeln();
      buf.writeln('**加密行情**');
      for (final q in market.crypto) {
        final arrow = q.changePercent >= 0 ? '📈' : '📉';
        buf.writeln(
            '· $arrow ${q.symbol} \$${_fmtPrice(q.price)} '
            '(${q.changePercent >= 0 ? '+' : ''}${q.changePercent.toStringAsFixed(2)}%)');
      }
    }

    // ── 贵金属 ──
    if (market.metals.isNotEmpty) {
      buf.writeln();
      buf.writeln('**贵金属**');
      for (final m in market.metals) {
        buf.writeln(
            '· ${m.code} ${m.priceFormatted} ${m.currency} '
            '(${m.changeFormatted})');
      }
    }

    // ── 今日要闻 ──
    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final top = sorted.take(5).toList();

    if (top.isNotEmpty) {
      buf.writeln();
      buf.writeln('**今日要闻**');
      buf.writeln();
      for (var i = 0; i < top.length; i++) {
        final a = top[i];
        buf.writeln('${i + 1}. **【${a.feedName}】** ${a.title}');
        if (a.summary != null && a.summary!.isNotEmpty) {
          buf.writeln('   > ${a.summary}');
        }
        buf.writeln();
      }
    } else {
      buf.writeln();
      buf.writeln('当前还没有加载文章，请先在「信息流」下拉刷新后再来生成播报。');
    }

    buf.writeln('---');
    buf.writeln('前往「脉搏」可查看市场情绪与实时行情，或问我具体话题。');
    return buf.toString();
  }

  String _fmtPrice(double v) {
    if (v >= 1000) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(4);
  }

  String _localReply(String message) {
    final cache = _ref.read(articleCacheProvider);
    final articles = cache.values.toList();
    final lower = message.toLowerCase();

    if (RegExp(r'今日|今天|最新|要闻|热点|新闻').hasMatch(message)) {
      return _localHighlights(articles);
    }

    if (RegExp(r'推荐|订阅|源|rss|关注').hasMatch(lower)) {
      return _localRecommendSources();
    }

    if (RegExp(r'亮点|头条|精选|重要').hasMatch(message)) {
      return _localHighlights(articles);
    }

    if (RegExp(r'总结|摘要|分析|洞察|趋势|insight|digest').hasMatch(message)) {
      return _localInsight(articles);
    }

    if (RegExp(r'黄金|贵金属|金价|白银|行情|金属|gold|metal').hasMatch(lower)) {
      return '关于贵金属行情，建议前往「市场 → 贵金属行情」查看实时金价和银价数据。';
    }

    if (RegExp(r'模型|API|排行榜|ai模型|hugging').hasMatch(lower)) {
      return '想了解最新 AI 模型排名？前往「市场 → AI 排行」查看 HuggingFace 趋势模型榜单。';
    }

    final matched = articles.where((a) {
      return a.title.toLowerCase().contains(lower) ||
          (a.summary?.toLowerCase().contains(lower) ?? false) ||
          a.feedName.toLowerCase().contains(lower);
    }).take(3).toList();

    if (matched.isEmpty) {
      return '我在当前已加载的文章中没找到与「$message」直接相关的内容。\n\n'
          '你可以：\n'
          '• 换个关键词再试\n'
          '• 在信息流下拉加载更多文章\n'
          '• 问我「今日要闻」或「推荐订阅源」';
    }

    final lines = matched.map((a) =>
        '【${a.feedName}】${a.title}${a.summary != null ? '\n  ${a.summary}' : ''}');
    return '找到 ${matched.length} 篇与「$message」相关的文章：\n\n${lines.join('\n\n')}';
  }

  String _localHighlights(List<Article> articles) {
    if (articles.isEmpty) {
      return '当前还没有加载文章，请先在「信息流」下拉刷新加载内容，我就能为你整理要闻了。';
    }
    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final top = sorted.take(5).toList();
    final buf = StringBuffer('📰 **今日新闻亮点**\n\n');
    for (var i = 0; i < top.length; i++) {
      final a = top[i];
      buf.writeln('${i + 1}. **【${a.feedName}】** ${a.title}');
      if (a.summary != null) {
        buf.writeln('   > ${a.summary}');
      }
      buf.writeln();
    }
    buf.write('---\n需要我详细解读某条新闻吗？或问我「总结趋势」获取今日洞察。');
    return buf.toString();
  }

  String _localInsight(List<Article> articles) {
    if (articles.length < 3) {
      return '文章不足，无法生成洞察。请先在信息流加载更多内容。';
    }
    final bySource = <String, List<Article>>{};
    for (final a in articles) {
      bySource.putIfAbsent(a.feedName, () => []).add(a);
    }
    final activeSources = bySource.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '• **${e.key}**（${e.value.length} 篇）')
        .join('\n');

    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final latest = sorted.take(3).map((a) =>
        '• **${a.feedName}**：${a.title}').join('\n');

    final categories = <String, int>{};
    for (final a in articles) {
      categories[a.feedName] = (categories[a.feedName] ?? 0) + 1;
    }
    final sortedCats = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = sortedCats.isNotEmpty ? sortedCats.first.key : '科技';

    return '📊 **今日内容洞察**\n\n'
        '**活跃来源**\n$activeSources\n\n'
        '**最新动态**\n$latest\n\n'
        '**热度分析**\n'
        '• 今日最活跃来源：**$topCat**\n'
        '• 共收录 ${articles.length} 篇文章\n'
        '• 覆盖 ${bySource.length} 个来源\n\n'
        '---\n前往「信息流」查看更多内容，或问我具体话题。';
  }

  String _localRecommendSources() {
    final groups = <String, List<String>>{};
    for (final s in RssSources.all) {
      groups.putIfAbsent(s.category.label, () => [])
          .add('${s.name}（${s.description}）');
    }
    final buf = StringBuffer('这里有一些优质订阅源推荐：\n\n');
    groups.forEach((cat, list) {
      buf.writeln('【$cat】');
      for (final l in list) {
        buf.writeln('· $l');
      }
      buf.writeln();
    });
    buf.write('前往「信息流 → 订阅管理」即可添加这些源。');
    return buf.toString();
  }

  Future<String> _callLlm(String userMessage, AiConfigState config) async {
    final dio = _ref.read(dioProvider);

    final cache = _ref.read(articleCacheProvider);
    final context = cache.values.take(15).map((a) =>
        '- 【${a.feedName}】${a.title}${a.summary != null ? '：${a.summary}' : ''}')
        .join('\n');

    final resp = await dio.post<Map<String, dynamic>>(
      '${config.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
      data: {
        'model': config.model,
        'messages': [
          {
            'role': 'system',
            'content': '你是 InfoFlow 的 AI 助手，帮用户总结和回答关于订阅内容的问题。'
                '以下是用户最近订阅的文章，回答时可参考：\n$context'
          },
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.7,
      },
    );

    final choices = resp.data?['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('LLM 返回为空');
    }
    final content = choices.first['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('LLM 返回内容为空');
    }
    return content.trim();
  }
}

final aiServiceProvider = Provider<AiService>((ref) => AiService(ref));
