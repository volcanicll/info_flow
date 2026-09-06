import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/ai_config.dart';
import '../../feed/presentation/controllers/article_cache.dart';
import '../../../features/feed/domain/entities/article.dart';
import '../../../features/market/data/fear_greed_repository.dart';
import '../../../features/market/data/market_repository.dart';
import '../../../features/market/domain/models/fear_greed_index.dart';
import '../../../features/market/domain/models/market_quote.dart';
import '../../../features/smart_money/data/smart_money_briefing.dart';

class AiService {
  AiService(this._ref);
  final Ref _ref;

  /// 聪明钱简报缓存：10 分钟 TTL，避免每轮对话都打上游接口。
  String? _smartBriefCache;
  DateTime _smartBriefAt = DateTime.fromMillisecondsSinceEpoch(0);

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

  /// 聪明钱简报：超过 TTL 就重新拉取，失败时保留旧值或返回 null。
  Future<String?> _smartBrief() async {
    if (DateTime.now().difference(_smartBriefAt) <
        const Duration(minutes: 10)) {
      return _smartBriefCache;
    }
    final brief = await fetchSmartBriefing(_ref);
    if (brief != null) {
      _smartBriefCache = brief;
      _smartBriefAt = DateTime.now();
    }
    return _smartBriefCache;
  }

  /// 每日播报：聚合链上情绪（恐惧贪婪 / 加密行情）与最新链上要闻
  Future<String> dailyBrief() async {
    final config = _ref.read(aiConfigProvider);
    if (config.apiKey.trim().isNotEmpty) {
      try {
        return await _callLlm('请生成今天的链上加密与生态每日播报', config);
      } catch (_) {
        return _localDailyBrief(await _fetchMarketSnapshot());
      }
    }
    return _localDailyBrief(await _fetchMarketSnapshot());
  }

  /// 并行拉取市场快照（恐惧贪婪指数 + 核心生态币行情）
  Future<({FearGreedIndex? fng, List<MarketQuote> crypto})>
      _fetchMarketSnapshot() async {
    final fearRepo = _ref.read(fearGreedRepositoryProvider);
    final marketRepo = _ref.read(marketRepositoryProvider);

    final results = await Future.wait([
      fearRepo.fetchIndex(),
      marketRepo.fetchCryptoQuotes(['BTC', 'ETH', 'SOL', 'BNB']),
    ]);

    return (
      fng: results[0] as FearGreedIndex?,
      crypto: results[1] as List<MarketQuote>,
    );
  }

  String _localDailyBrief(
    ({FearGreedIndex? fng, List<MarketQuote> crypto}) market,
  ) {
    final cache = _ref.read(articleCacheProvider);
    final articles = cache.values.toList();
    final buf = StringBuffer();

    buf.writeln('⚡ **链上加密情报每日播报**');
    buf.writeln();

    // ── 市场情绪 ──
    final fng = market.fng;
    if (fng != null) {
      buf.writeln('**市场情绪指数**：${fng.classification}（${fng.value}/100）');
    }

    // ── 核心标的行情 ──
    if (market.crypto.isNotEmpty) {
      buf.writeln();
      buf.writeln('**四大生态基准标的**');
      for (final q in market.crypto) {
        final arrow = q.changePercent >= 0 ? '📈' : '📉';
        buf.writeln(
            '· $arrow **${q.symbol}** \$${_fmtPrice(q.price)} '
            '(${q.changePercent >= 0 ? '+' : ''}${q.changePercent.toStringAsFixed(2)}%)');
      }
    }

    // ── 今日链上情报 ──
    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final top = sorted.take(5).toList();

    if (top.isNotEmpty) {
      buf.writeln();
      buf.writeln('**链上要闻与生态速递**');
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
      buf.writeln('当前情报流尚未拉取，请在「情报」页面下拉刷新获取最新动态。');
    }

    buf.writeln('---');
    buf.writeln('提示：在「探测」页面可输入任意 CA 地址进行 GoPlus 貔貅安全检测，或在「雷达」追踪 Robinhood / Solana / Base / BSC 异动。');
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

    // 1. 合约安全与貔貅检测引导
    if (RegExp(r'合约|安全|貔貅|honeypot|rug|税|审计|开源').hasMatch(lower)) {
      return '🛡️ **代币合约安全审计指引**\n\n'
          '你可以直接在「探测 (Screener)」页面输入代币合约地址（CA），平台将通过 GoPlus 自动化执行：\n'
          '• **貔貅检测**：验证是否可正常卖出\n'
          '• **买卖税率**：检测买税/卖税是否过高\n'
          '• **权限审计**：检查铸造权 (Mint) 与冻结权 (Freeze) 是否已丢弃\n'
          '• **持仓集中度**：Top 10 持币大户占比分析\n\n'
          '立即前往底栏「探测」页面开始体检！';
    }

    // 2. 四大链生态问答
    if (lower.contains('solana') || lower.contains('sol') || lower.contains('pump')) {
      return '🟣 **Solana 链上动态**\n\n'
          'Solana 当前以极低 Gas 和高 TPS 驱动 Meme 与 DeFi 生态（如 Pump.fun, Raydium, Jupiter）。\n'
          '前往「雷达 → Solana」可查看热门流动性池与发射异动；在情报流可过滤 Solana 官方博客与 Solana Floor 动态。';
    }

    if (lower.contains('base') || lower.contains('clanker') || lower.contains('virtual')) {
      return '🔵 **Base 链上动态**\n\n'
          'Base 是 Coinbase 孵化的以太坊 L2，目前 AI Agent 代币（Virtuals / Clanker）与 Aerodrome 活跃度极高。\n'
          '前往「雷达 → Base」可实时监控 Base 交易量靠前的交易对与智能合约安全性。';
    }

    if (lower.contains('bsc') || lower.contains('bnb') || lower.contains('four')) {
      return '🟡 **BSC (BNB Smart Chain) 动态**\n\n'
          'BSC 生态以 PancakeSwap 与 Four.meme 为核心，流动性充足。\n'
          '进行 BSC 代币交互时请务必使用「探测」检测是否存在恶意黑名单或超高买卖税。';
    }

    if (lower.contains('robinhood') || lower.contains('hood')) {
      return '🟢 **Robinhood 加密与链上布局**\n\n'
          'Robinhood 不仅支持 BTC, ETH, SOL, DOGE, SHIB, PEPE 等现货资产交易，其自建 Robinhood Chain 及与 Arbitrum 的合作正在加速落地。\n'
          '前往「雷达 → Robinhood」可专属监控 Robinhood 官方上架资产涨跌幅与异动排行榜。';
    }

    if (RegExp(r'今日|今天|最新|要闻|热点|新闻').hasMatch(message)) {
      return _localHighlights(articles);
    }

    final matched = articles.where((a) {
      return a.title.toLowerCase().contains(lower) ||
          (a.summary?.toLowerCase().contains(lower) ?? false) ||
          a.feedName.toLowerCase().contains(lower);
    }).take(3).toList();

    if (matched.isEmpty) {
      return '我在当前链上情报库中暂未找到与「$message」直接相关的内容。\n\n'
          '你可以：\n'
          '• 在「探测」页面输入合约地址或代币 Symbol 进行全链检索\n'
          '• 询问「Solana」、「Base」、「BSC」或「Robinhood」生态情况\n'
          '• 问我「今日要闻」或「每日播报」';
    }

    final lines = matched.map((a) =>
        '【${a.feedName}】${a.title}${a.summary != null ? '\n  ${a.summary}' : ''}');
    return '找到 ${matched.length} 篇与「$message」相关的链上情报：\n\n${lines.join('\n\n')}';
  }

  String _localHighlights(List<Article> articles) {
    if (articles.isEmpty) {
      return '当前还没有加载文章，请先在「情报」页面下拉刷新，我就能为你整理链上要闻了。';
    }
    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final top = sorted.take(5).toList();
    final buf = StringBuffer('⚡ **今日链上核心要闻**\n\n');
    for (var i = 0; i < top.length; i++) {
      final a = top[i];
      buf.writeln('${i + 1}. **【${a.feedName}】** ${a.title}');
      if (a.summary != null) {
        buf.writeln('   > ${a.summary}');
      }
      buf.writeln();
    }
    buf.write('---\n提示：点击新闻卡片上的代币徽章，可直达代币探测与安全审计。');
    return buf.toString();
  }

  Future<String> _callLlm(String userMessage, AiConfigState config) async {
    final dio = _ref.read(dioProvider);

    final cache = _ref.read(articleCacheProvider);
    final context = cache.values.take(15).map((a) =>
        '- 【${a.feedName}】${a.title}${a.summary != null ? '：${a.summary}' : ''}')
        .join('\n');

    // 聪明钱简报：懒加载 + TTL，拉不到时静默降级为纯资讯上下文
    final smartBrief = await _smartBrief();

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
            'content': '你是 InfoFlow 生产级链上智能投研助手，专注于 Robinhood、BSC、Base、Solana 四大区块链生态及全链加密情报分析。为你提供准确、专业、去伪存真的链上数据解读、代币合约安全评估与Alpha洞察。'
                '以下是系统最新捕获的链上情报，回答时可参考：\n$context'
                '${smartBrief == null ? '' : '\n$smartBrief'}'
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
