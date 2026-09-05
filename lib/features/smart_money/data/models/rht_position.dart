import 'rht_models.dart';

/// 已平仓战绩（REST /api/closed）：一次完整的建仓→清仓周期。
class RhtClosedPosition {
  final String wallet;
  final String token;
  final int openedTs;
  final int closedTs;
  final double costSold;
  final double proceedsUsd;
  final double pnlUsd;
  final double pnlPct;
  final int buys;
  final int sells;
  final String handle;
  final int followers;
  final String profileUrl;
  final String symbol;
  final int holdSeconds;

  const RhtClosedPosition({
    required this.wallet,
    required this.token,
    required this.openedTs,
    required this.closedTs,
    required this.costSold,
    required this.proceedsUsd,
    required this.pnlUsd,
    required this.pnlPct,
    required this.buys,
    required this.sells,
    required this.handle,
    required this.followers,
    required this.profileUrl,
    required this.symbol,
    required this.holdSeconds,
  });

  factory RhtClosedPosition.fromJson(Map<String, dynamic> j) =>
      RhtClosedPosition(
        wallet: j['wallet'] as String? ?? '',
        token: j['token'] as String? ?? '',
        openedTs: j.i('opened_ts') ?? 0,
        closedTs: j.i('closed_ts') ?? 0,
        costSold: j.d('cost_sold') ?? 0,
        proceedsUsd: j.d('proceeds_usd') ?? 0,
        pnlUsd: j.d('pnl_usd') ?? 0,
        pnlPct: j.d('pnl_pct') ?? 0,
        buys: j.i('buys') ?? 0,
        sells: j.i('sells') ?? 0,
        handle: j['handle'] as String? ?? '—',
        followers: j.i('followers') ?? 0,
        profileUrl: j['profile_url'] as String? ?? '',
        symbol: j['symbol'] as String? ?? '???',
        holdSeconds: j.i('hold_seconds') ?? 0,
      );
}
