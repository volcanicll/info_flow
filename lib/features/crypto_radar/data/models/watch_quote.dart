/// 自选币的实时报价快照（Binance 24h ticker）。
class WatchQuote {
  final String coin;
  final double price;
  final double changePercent;
  final double volume;

  const WatchQuote({
    required this.coin,
    required this.price,
    required this.changePercent,
    required this.volume,
  });

  bool get isUp => changePercent > 0;
}
