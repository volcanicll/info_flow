import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/rht_models.dart';
import 'models/rht_token.dart';
import 'models/rht_trader.dart';
import 'smart_money_repository.dart';

/// 聪明钱情报简报：把 24h 总览 + 大户榜 + 跟单链渲染成给 LLM 的结构化文本。
///
/// 由 AiService 以 10 分钟 TTL 懒加载注入系统提示词；上游不可达时返回
/// null，AI 回答退化为纯资讯上下文，不影响可用性。
Future<String?> fetchSmartBriefing(Ref ref) async {
  final repo = ref.read(smartMoneyRepositoryProvider);
  try {
    final overview = await repo.fetchOverview();
    final traders = await repo.fetchTraders().catchError((_) => <RhtTrader>[]);
    final flows =
        await repo.fetchFlowChains().catchError((_) => <RhtFlowChain>[]);
    return _render(overview, traders, flows);
  } catch (_) {
    return null;
  }
}

String _render(
    RhtOverview o, List<RhtTrader> traders, List<RhtFlowChain> flows) {
  final buf = StringBuffer();
  buf.writeln('【聪明钱 24h 动态（Robinhood 链 ${'被追踪大户'}）】');
  buf.writeln(
      '- 成交 ${o.fills} 笔（买 ${o.buys}/卖 ${o.sells}），${o.activeTraders} 位大户活跃，'
      '总成交额 \$${_compact(o.volume)}');
  buf.writeln(
      '- 已实现盈亏 \$${_compact(o.realizedPnl)}，未实现 \$${_compact(o.unrealizedPnl)}，'
      '净盈亏 \$${_compact(o.netPnl)}，平仓胜率 ${(o.winRate * 100).toStringAsFixed(0)}%');
  if (o.biggestWin != null) {
    buf.writeln(
        '- 最大赢家：${o.biggestWin!.handle} 在 ${o.biggestWin!.symbol} 上赚 '
        '\$${_compact(o.biggestWin!.usd)}（${o.biggestWin!.pct?.toStringAsFixed(0) ?? '?'}%）');
  }
  if (o.biggestBuy != null) {
    buf.writeln(
        '- 最大买单：${o.biggestBuy!.handle} 买入 ${o.biggestBuy!.symbol} '
        '\$${_compact(o.biggestBuy!.usd)}');
  }
  final top = traders.take(5).toList();
  if (top.isNotEmpty) {
    buf.writeln('- 净盈亏前五的大户：');
    for (final (i, t) in top.indexed) {
      buf.writeln(
          '  ${i + 1}. ${t.title}（${_compactF(t.followers)}粉）净 '
          '\$${_compact(t.netPnl)}，${t.fills} 笔成交，仓位状态 ${t.state}');
    }
  }
  final chains = flows.where((f) => f.followers.isNotEmpty).take(3).toList();
  if (chains.isNotEmpty) {
    buf.writeln('- 大户抱团跟单链：');
    for (final c in chains) {
      buf.writeln(
          '  · ${c.symbol}：${c.lead.handle} 领买 \$${_compact(c.lead.usd)}，'
          '${c.followers.length} 位大户在数秒到数分钟内跟进，合计 \$${_compact(c.totalUsd)}');
    }
  }
  buf.writeln('（数据源 robinhoodtrenches.com 实盘索引，回答涉及聪明钱话题时优先引用）');
  return buf.toString();
}

String _compact(double v) {
  final a = v.abs();
  final sign = v < 0 ? '-' : '';
  if (a >= 1e9) return '$sign${(a / 1e9).toStringAsFixed(2)}B';
  if (a >= 1e6) return '$sign${(a / 1e6).toStringAsFixed(2)}M';
  if (a >= 1e4) return '$sign${a.round()}';
  return '$sign${a.toStringAsFixed(0)}';
}

String _compactF(int v) {
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
  return '$v';
}
