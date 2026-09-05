library;

/// robinhoodtrenches.com 数据模型：索引器状态 / 24h 总览 / 实盘成交。
///
/// 上游字段大量可空（未定价、未成交、字典缺失均返回 null），
/// 因此数值统一用 [RhtNum] 安全转换，缺省返回 null 或 0。

/// JSON 数值安全转换：上游同一字段可能在 int/double/String 间漂移。
extension RhtNum on Map<String, dynamic> {
  double? d(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  int? i(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  bool b(String key) => this[key] == true || this[key] == 1;

  String? s(String key) => this[key]?.toString();
}

/// 索引器健康状态（REST /api/status，也是 WS hello 消息的 payload）。
class RhtStatus {
  final String chain;
  final int chainId;
  final int wallets;
  final int trades;
  final double lagSeconds;
  final int lastBlock;
  final int viewers;
  final int lastTs;
  final int serverTs;
  final double latencyMedian;
  final double latencyP90;

  const RhtStatus({
    required this.chain,
    required this.chainId,
    required this.wallets,
    required this.trades,
    required this.lagSeconds,
    required this.lastBlock,
    required this.viewers,
    required this.lastTs,
    required this.serverTs,
    required this.latencyMedian,
    required this.latencyP90,
  });

  factory RhtStatus.fromJson(Map<String, dynamic> j) => RhtStatus(
        chain: j['chain'] as String? ?? 'robinhood',
        chainId: j.i('chain_id') ?? 0,
        wallets: j.i('wallets') ?? 0,
        trades: j.i('trades') ?? 0,
        lagSeconds: j.d('lag_seconds') ?? 0,
        lastBlock: j.i('last_block') ?? 0,
        viewers: j.i('viewers') ?? 0,
        lastTs: j.i('last_ts') ?? 0,
        serverTs: j.i('server_ts') ?? 0,
        latencyMedian: (j['latency'] as Map<String, dynamic>?)?.d('median') ?? 0,
        latencyP90: (j['latency'] as Map<String, dynamic>?)?.d('p90') ?? 0,
      );
}

/// 窗口期总览（REST /api/overview）。
class RhtOverview {
  final int fills;
  final int buys;
  final int sells;
  final int activeTraders;
  final int tokens;
  final double volume;
  final double realizedPnl;
  final double unrealizedPnl;
  final double netPnl;
  final double winRate;
  final int closedTrades;
  final int openBags;
  final RhtHighlightTrade? biggestWin;
  final RhtHighlightTrade? biggestBuy;
  final int last5mBuys;
  final int last5mSells;

  const RhtOverview({
    required this.fills,
    required this.buys,
    required this.sells,
    required this.activeTraders,
    required this.tokens,
    required this.volume,
    required this.realizedPnl,
    required this.unrealizedPnl,
    required this.netPnl,
    required this.winRate,
    required this.closedTrades,
    required this.openBags,
    this.biggestWin,
    this.biggestBuy,
    required this.last5mBuys,
    required this.last5mSells,
  });

  factory RhtOverview.fromJson(Map<String, dynamic> j) => RhtOverview(
        fills: j.i('fills') ?? 0,
        buys: j.i('buys') ?? 0,
        sells: j.i('sells') ?? 0,
        activeTraders: j.i('active_traders') ?? 0,
        tokens: j.i('tokens') ?? 0,
        volume: j.d('volume') ?? 0,
        realizedPnl: j.d('realized_pnl') ?? 0,
        unrealizedPnl: j.d('unrealized_pnl') ?? 0,
        netPnl: j.d('net_pnl') ?? 0,
        winRate: j.d('win_rate') ?? 0,
        closedTrades: j.i('closed_trades') ?? 0,
        openBags: j.i('open_bags') ?? 0,
        biggestWin: (j['biggest_win'] as Map<String, dynamic>?)
            .andThen(RhtHighlightTrade.fromJson),
        biggestBuy: (j['biggest_buy'] as Map<String, dynamic>?)
            .andThen(RhtHighlightTrade.fromJson),
        last5mBuys: (j['last_5m'] as Map<String, dynamic>?)?.i('buys') ?? 0,
        last5mSells: (j['last_5m'] as Map<String, dynamic>?)?.i('sells') ?? 0,
      );
}

/// 总览里的「最大赢家 / 最大买单」摘要。
class RhtHighlightTrade {
  final String handle;
  final String symbol;
  final double usd;
  final double? pct;

  const RhtHighlightTrade({
    required this.handle,
    required this.symbol,
    required this.usd,
    this.pct,
  });

  factory RhtHighlightTrade.fromJson(Map<String, dynamic> j) => RhtHighlightTrade(
        handle: j['handle'] as String? ?? '—',
        symbol: j['symbol'] as String? ?? '—',
        usd: j.d('pnl_usd') ?? j.d('usd') ?? 0,
        pct: j.d('pct'),
      );
}

/// 实盘成交（WS fills 推送 / REST /api/tape 行）。
class RhtFill {
  final int id;
  final int ts;
  final String tx;
  final bool isBuy;
  final double usd;
  final double amount;
  final double? price;
  final bool isNewPosition;
  final String handle;
  final String? displayName;
  final int followers;
  final String wallet;
  final String token;
  final String symbol;
  final double? mark;
  final double? liquidity;
  final String? pairUrl;

  /// 上游标注的附加标签（如 'new wallet'）。
  final List<String> flags;

  const RhtFill({
    required this.id,
    required this.ts,
    required this.tx,
    required this.isBuy,
    required this.usd,
    required this.amount,
    required this.price,
    required this.isNewPosition,
    required this.handle,
    required this.displayName,
    required this.followers,
    required this.wallet,
    required this.token,
    required this.symbol,
    required this.mark,
    required this.liquidity,
    required this.pairUrl,
    required this.flags,
  });

  factory RhtFill.fromJson(Map<String, dynamic> j) => RhtFill(
        id: j.i('id') ?? 0,
        ts: j.i('ts') ?? 0,
        tx: j['tx'] as String? ?? '',
        isBuy: j['side'] == 'buy',
        usd: j.d('usd') ?? 0,
        amount: j.d('amount') ?? 0,
        price: j.d('price'),
        isNewPosition: (j.i('new_position') ?? 0) == 1,
        handle: j['handle'] as String? ?? '—',
        displayName: j['display_name'] as String?,
        followers: j.i('followers') ?? 0,
        wallet: j['wallet'] as String? ?? '',
        token: j['token'] as String? ?? '',
        symbol: j['symbol'] as String? ?? '???',
        mark: j.d('mark'),
        liquidity: j.d('liquidity'),
        pairUrl: j['pair_url'] as String?,
        flags: (j['flags'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

extension NullableMapX on Map<String, dynamic>? {
  R? andThen<R>(R Function(Map<String, dynamic>) f) {
    final self = this;
    return self == null ? null : f(self);
  }
}
