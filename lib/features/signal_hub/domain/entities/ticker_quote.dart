import 'ticker_ref.dart';

/// 某标的的实时报价快照。
class TickerQuote {
  final String symbol;
  final AssetClass asset;
  final double price;
  final double changePercent;

  const TickerQuote({
    required this.symbol,
    required this.asset,
    required this.price,
    required this.changePercent,
  });

  bool get isUp => changePercent > 0;
}
