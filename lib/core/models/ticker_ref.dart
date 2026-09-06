/// 标的资产大类
enum AssetClass { crypto, metal, macro, usStock, cnStock }

/// 文章中识别出的某个金融标的的引用。
class TickerRef {
  final String symbol; // 统一符号：'ETH' / 'XAU' / 'DXY'
  final AssetClass asset;
  final int mentions; // 全文出现次数
  final bool inTitle; // 是否出现在标题（权重更高）

  const TickerRef({
    required this.symbol,
    required this.asset,
    required this.mentions,
    required this.inTitle,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'asset': asset.name,
        'mentions': mentions,
        'inTitle': inTitle,
      };

  factory TickerRef.fromJson(Map<String, dynamic> json) => TickerRef(
        symbol: json['symbol'] as String,
        asset: AssetClass.values.byName(json['asset'] as String),
        mentions: json['mentions'] as int? ?? 1,
        inTitle: json['inTitle'] as bool? ?? false,
      );
}
