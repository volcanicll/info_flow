class TradeSignal {
  final String coin;
  final String sym;
  final String direction;
  final int score;
  final String strategy;
  final double price;
  final double entry;
  final double sl;
  final double tp;
  final double slPct;
  final double margin;
  final double notional;
  final double risk;
  final List<String> tags;
  final String urgency;

  const TradeSignal({
    required this.coin,
    required this.sym,
    required this.direction,
    required this.score,
    required this.strategy,
    required this.price,
    required this.entry,
    required this.sl,
    required this.tp,
    required this.slPct,
    required this.margin,
    required this.notional,
    required this.risk,
    required this.tags,
    required this.urgency,
  });
}
