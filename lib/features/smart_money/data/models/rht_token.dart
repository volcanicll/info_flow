import 'rht_models.dart';

/// 代币聚合（REST /api/tokens）：窗口期内被追踪钱包的净买卖与首买信息。
class RhtTokenFlow {
  final String token;
  final String symbol;
  final String name;
  final int traders;
  final int buyers;
  final double usdIn;
  final double usdOut;
  final double netUsd;
  final int lastTs;
  final double? mark;
  final double? liquidity;
  final double? change24;
  final double? volume24;
  final String? pairUrl;
  final RhtFirstBuyer? firstBuyer;
  final double? sinceFirstBuyPct;
  final int holders;

  const RhtTokenFlow({
    required this.token,
    required this.symbol,
    required this.name,
    required this.traders,
    required this.buyers,
    required this.usdIn,
    required this.usdOut,
    required this.netUsd,
    required this.lastTs,
    required this.mark,
    required this.liquidity,
    required this.change24,
    required this.volume24,
    required this.pairUrl,
    required this.firstBuyer,
    required this.sinceFirstBuyPct,
    required this.holders,
  });

  factory RhtTokenFlow.fromJson(Map<String, dynamic> j) => RhtTokenFlow(
        token: j['token'] as String? ?? '',
        symbol: j['symbol'] as String? ?? '???',
        name: j['name'] as String? ?? '',
        traders: j.i('traders') ?? 0,
        buyers: j.i('buyers') ?? 0,
        usdIn: j.d('usd_in') ?? 0,
        usdOut: j.d('usd_out') ?? 0,
        netUsd: j.d('net_usd') ?? 0,
        lastTs: j.i('last_ts') ?? 0,
        mark: j.d('mark'),
        liquidity: j.d('liquidity'),
        change24: j.d('change24'),
        volume24: j.d('volume24'),
        pairUrl: j['pair_url'] as String?,
        firstBuyer: (j['first_buyer'] as Map<String, dynamic>?)
            .andThen(RhtFirstBuyer.fromJson),
        sinceFirstBuyPct: j.d('since_first_buy_pct'),
        holders: j.i('holders') ?? 0,
      );
}

/// 聪明钱首位买家（含粉丝量，用于判断信号含金量）。
class RhtFirstBuyer {
  final String handle;
  final int followers;
  final int ts;
  final double? price;

  const RhtFirstBuyer({
    required this.handle,
    required this.followers,
    required this.ts,
    required this.price,
  });

  factory RhtFirstBuyer.fromJson(Map<String, dynamic> j) => RhtFirstBuyer(
        handle: j['handle'] as String? ?? '—',
        followers: j.i('followers') ?? 0,
        ts: j.i('ts') ?? 0,
        price: j.d('price'),
      );
}

/// 跟单链（REST /api/flow）：领买人买入后，其他被追踪钱包的跟进情况。
class RhtFlowChain {
  final String token;
  final String symbol;
  final String name;
  final RhtFlowTrader lead;
  final List<RhtFlowFollower> followers;
  final double totalUsd;
  final double? sinceLeadPct;
  final String? pairUrl;

  const RhtFlowChain({
    required this.token,
    required this.symbol,
    required this.name,
    required this.lead,
    required this.followers,
    required this.totalUsd,
    required this.sinceLeadPct,
    required this.pairUrl,
  });

  factory RhtFlowChain.fromJson(Map<String, dynamic> j) => RhtFlowChain(
        token: j['token'] as String? ?? '',
        symbol: j['symbol'] as String? ?? '???',
        name: j['name'] as String? ?? '',
        lead: RhtFlowTrader.fromJson(
            j['lead'] as Map<String, dynamic>? ?? const {}),
        followers: (j['followers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RhtFlowFollower.fromJson)
            .toList(),
        totalUsd: j.d('total_usd') ?? 0,
        sinceLeadPct: j.d('since_lead_pct'),
        pairUrl: j['pair_url'] as String?,
      );
}

/// 领买人。
class RhtFlowTrader {
  final String handle;
  final int followers;
  final int ts;
  final double usd;
  final double? price;
  final String wallet;

  const RhtFlowTrader({
    required this.handle,
    required this.followers,
    required this.ts,
    required this.usd,
    required this.price,
    required this.wallet,
  });

  factory RhtFlowTrader.fromJson(Map<String, dynamic> j) => RhtFlowTrader(
        handle: j['handle'] as String? ?? '—',
        followers: j.i('followers') ?? 0,
        ts: j.i('ts') ?? 0,
        usd: j.d('usd') ?? 0,
        price: j.d('price'),
        wallet: j['wallet'] as String? ?? '',
      );
}

/// 跟随者（含滞后秒数——「领买后 N 秒跟进」是本接口的核心价值）。
class RhtFlowFollower {
  final String handle;
  final int followers;
  final int ts;
  final double usd;
  final double? lagSeconds;

  const RhtFlowFollower({
    required this.handle,
    required this.followers,
    required this.ts,
    required this.usd,
    required this.lagSeconds,
  });

  factory RhtFlowFollower.fromJson(Map<String, dynamic> j) => RhtFlowFollower(
        handle: j['handle'] as String? ?? '—',
        followers: j.i('followers') ?? 0,
        ts: j.i('ts') ?? 0,
        usd: j.d('usd') ?? 0,
        lagSeconds: j.d('lag_seconds'),
      );
}

/// 聪明钱雷达（REST /api/radar）：近 N 分钟被追踪钱包首买的新币。
class RhtRadarItem {
  final String token;
  final String symbol;
  final String name;
  final int firstTs;
  final int buyers;
  final double usdIn;
  final double? mark;
  final double? liquidity;
  final double? change24;
  final int? poolAge;
  final int? ageAtFirstBuy;
  final bool fresh;
  final RhtFirstBuyer? firstBuyer;

  const RhtRadarItem({
    required this.token,
    required this.symbol,
    required this.name,
    required this.firstTs,
    required this.buyers,
    required this.usdIn,
    required this.mark,
    required this.liquidity,
    required this.change24,
    required this.poolAge,
    required this.ageAtFirstBuy,
    required this.fresh,
    required this.firstBuyer,
  });

  factory RhtRadarItem.fromJson(Map<String, dynamic> j) => RhtRadarItem(
        token: j['token'] as String? ?? '',
        symbol: j['symbol'] as String? ?? '???',
        name: j['name'] as String? ?? '',
        firstTs: j.i('first_ts') ?? 0,
        buyers: j.i('buyers') ?? 0,
        usdIn: j.d('usd_in') ?? 0,
        mark: j.d('mark'),
        liquidity: j.d('liquidity'),
        change24: j.d('change24'),
        poolAge: j.i('pool_age'),
        ageAtFirstBuy: j.i('age_at_first_buy'),
        fresh: j.b('fresh'),
        firstBuyer: (j['first_buyer'] as Map<String, dynamic>?)
            .andThen(RhtFirstBuyer.fromJson),
      );
}
