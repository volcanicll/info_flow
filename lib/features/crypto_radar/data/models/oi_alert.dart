class OiAlert {
  final String symbol;
  final String coin;
  final double price;
  final double oiUsd;
  final double oiDeltaPct;
  final double oiDeltaUsd;
  final double vol24h;
  final double pxChgPct;
  final double fundingRate;

  const OiAlert({
    required this.symbol,
    required this.coin,
    required this.price,
    required this.oiUsd,
    required this.oiDeltaPct,
    required this.oiDeltaUsd,
    required this.vol24h,
    required this.pxChgPct,
    required this.fundingRate,
  });
}
