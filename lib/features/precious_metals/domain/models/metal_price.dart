class MetalPrice {
  final String name;
  final String code;
  final String currency;
  final double price;
  final double changePercent;

  const MetalPrice({
    required this.name,
    required this.code,
    required this.currency,
    required this.price,
    required this.changePercent,
  });

  bool get isUp => changePercent >= 0;

  String get priceFormatted {
    if (price >= 1000) return price.toStringAsFixed(2);
    if (price >= 1) return price.toStringAsFixed(3);
    return price.toStringAsFixed(4);
  }

  String get changeFormatted =>
      '${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}
