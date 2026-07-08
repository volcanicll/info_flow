enum MarketType { crypto, cnStock, usStock, hkStock }

class MarketQuote {
  final String symbol;
  final String name;
  final MarketType market;
  final double price;
  final double changePercent;
  final double volume;
  final DateTime updatedAt;

  const MarketQuote({
    required this.symbol,
    required this.name,
    required this.market,
    required this.price,
    required this.changePercent,
    required this.volume,
    required this.updatedAt,
  });

  bool get isUp => changePercent > 0;
}
