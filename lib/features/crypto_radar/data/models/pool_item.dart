class PoolItem {
  final String symbol;
  final String coin;
  final int sidewaysDays;
  final double rangePct;
  final double slopePct;
  final double lowPrice;
  final double highPrice;
  final double avgVol;
  final double currentPrice;
  final double recentVol;
  final double volBreakout;
  final double score;
  final String status;

  const PoolItem({
    required this.symbol,
    required this.coin,
    required this.sidewaysDays,
    required this.rangePct,
    required this.slopePct,
    required this.lowPrice,
    required this.highPrice,
    required this.avgVol,
    required this.currentPrice,
    required this.recentVol,
    required this.volBreakout,
    required this.score,
    required this.status,
  });
}
