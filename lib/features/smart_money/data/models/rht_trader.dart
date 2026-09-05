import 'rht_models.dart';

/// 交易员排行榜行（REST /api/traders）。
class RhtTrader {
  final String address;
  final String handle;
  final String? displayName;
  final int followers;
  final String profileUrl;
  final double volume;
  final int fills;
  final int buys;
  final int sells;
  final int lastTs;
  final double realizedPnl;
  final double unrealizedPnl;
  final double netPnl;
  final int closedTrades;
  final int wins;
  final double? bestTrade;
  final double? worstTrade;
  final double? winRate;
  final int openBags;
  final double openValue;

  /// 上游仓位状态：flat / accumulating / draining。
  final String state;
  final bool active;

  const RhtTrader({
    required this.address,
    required this.handle,
    required this.displayName,
    required this.followers,
    required this.profileUrl,
    required this.volume,
    required this.fills,
    required this.buys,
    required this.sells,
    required this.lastTs,
    required this.realizedPnl,
    required this.unrealizedPnl,
    required this.netPnl,
    required this.closedTrades,
    required this.wins,
    required this.bestTrade,
    required this.worstTrade,
    required this.winRate,
    required this.openBags,
    required this.openValue,
    required this.state,
    required this.active,
  });

  factory RhtTrader.fromJson(Map<String, dynamic> j) => RhtTrader(
        address: j['address'] as String? ?? '',
        handle: j['handle'] as String? ?? '—',
        displayName: j['display_name'] as String?,
        followers: j.i('followers') ?? 0,
        profileUrl: j['profile_url'] as String? ?? '',
        volume: j.d('volume') ?? 0,
        fills: j.i('fills') ?? 0,
        buys: j.i('buys') ?? 0,
        sells: j.i('sells') ?? 0,
        lastTs: j.i('last_ts') ?? 0,
        realizedPnl: j.d('realized_pnl') ?? 0,
        unrealizedPnl: j.d('unrealized_pnl') ?? 0,
        netPnl: j.d('net_pnl') ?? 0,
        closedTrades: j.i('closed_trades') ?? 0,
        wins: j.i('wins') ?? 0,
        bestTrade: j.d('best_trade'),
        worstTrade: j.d('worst_trade'),
        winRate: j.d('win_rate'),
        openBags: j.i('open_bags') ?? 0,
        openValue: j.d('open_value') ?? 0,
        state: j['state'] as String? ?? 'flat',
        active: j.b('active'),
      );

  String get title => (displayName != null && displayName!.isNotEmpty)
      ? displayName!
      : handle;
}

/// 交易员详情（REST /api/trader/{handle}）。
class RhtTraderDetail {
  final String address;
  final String handle;
  final String? displayName;
  final int followers;
  final int numTrades;
  final double volumeUsd;
  final String joined;

  /// fomo.family 跨链身份（Solana 地址），可用于后续多链追踪。
  final String? solanaAddress;
  final String profileUrl;
  final List<RhtBag> bags;

  const RhtTraderDetail({
    required this.address,
    required this.handle,
    required this.displayName,
    required this.followers,
    required this.numTrades,
    required this.volumeUsd,
    required this.joined,
    required this.solanaAddress,
    required this.profileUrl,
    required this.bags,
  });

  factory RhtTraderDetail.fromJson(Map<String, dynamic> j) => RhtTraderDetail(
        address: j['address'] as String? ?? '',
        handle: j['handle'] as String? ?? '—',
        displayName: j['display_name'] as String?,
        followers: j.i('followers') ?? 0,
        numTrades: j.i('num_trades') ?? 0,
        volumeUsd: j.d('volume_usd') ?? 0,
        joined: j['joined'] as String? ?? '—',
        solanaAddress: j['solana_address'] as String?,
        profileUrl: j['profile_url'] as String? ?? '',
        bags: (j['bags'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RhtBag.fromJson)
            .toList(),
      );

  String get title => (displayName != null && displayName!.isNotEmpty)
      ? displayName!
      : handle;
}

/// 当前持仓（bag）。
class RhtBag {
  final String token;
  final String symbol;
  final String name;
  final double amount;
  final double costUsd;
  final double avgPrice;
  final int openedTs;
  final double? mark;
  final double? value;
  final double? pnl;
  final double? pnlPct;
  final int ageSeconds;

  const RhtBag({
    required this.token,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.costUsd,
    required this.avgPrice,
    required this.openedTs,
    required this.mark,
    required this.value,
    required this.pnl,
    required this.pnlPct,
    required this.ageSeconds,
  });

  factory RhtBag.fromJson(Map<String, dynamic> j) => RhtBag(
        token: j['token'] as String? ?? '',
        symbol: j['symbol'] as String? ?? '???',
        name: j['name'] as String? ?? '',
        amount: j.d('amount') ?? 0,
        costUsd: j.d('cost_usd') ?? 0,
        avgPrice: j.d('avg_price') ?? 0,
        openedTs: j.i('opened_ts') ?? 0,
        mark: j.d('mark'),
        value: j.d('value'),
        pnl: j.d('pnl'),
        pnlPct: j.d('pnl_pct'),
        ageSeconds: j.i('age_seconds') ?? 0,
      );
}
