import '../domain/entities/ticker_ref.dart';

/// 词典单条：一个标的 + 它的若干匹配别名（已小写、去标点）。
class DictEntry {
  final String symbol;
  final AssetClass asset;
  final List<String> aliases;
  const DictEntry(this.symbol, this.asset, this.aliases);
}

/// 本地标的词典（P0 覆盖主流加密 + 贵金属 + 少量宏观标签）。
/// 设计为可热更新，P1/P2 扩展美股/A股时只需补充条目。
class TickerDictionary {
  TickerDictionary._();
  static final TickerDictionary instance = TickerDictionary._();
  factory TickerDictionary() => instance;

  List<DictEntry> get entries => const [
        // 加密货币：符号 + 中文名 + 常见别名
        DictEntry('BTC', AssetClass.crypto, ['btc', '比特币', '大饼', 'btc币']),
        DictEntry('ETH', AssetClass.crypto, ['eth', '以太坊', '以太', '以太币']),
        DictEntry('BNB', AssetClass.crypto, ['bnb', '币安币']),
        DictEntry('SOL', AssetClass.crypto, ['sol', '索拉纳', 'solana']),
        DictEntry('XRP', AssetClass.crypto, ['xrp', '瑞波', '瑞波币', 'ripple']),
        DictEntry('DOGE', AssetClass.crypto, ['doge', '狗狗币', 'dogecoin']),
        DictEntry('ADA', AssetClass.crypto, ['ada', '艾达币', 'cardano']),
        DictEntry('AVAX', AssetClass.crypto, ['avax', '雪崩', 'avalanche']),
        DictEntry('LINK', AssetClass.crypto, ['link', '链link', 'chainlink']),
        DictEntry('MATIC', AssetClass.crypto, ['matic', '马蹄', 'polygon']),
        // 贵金属
        DictEntry('XAU', AssetClass.metal, ['xau', '黄金', '纽约金', '国际金']),
        DictEntry('XAG', AssetClass.metal, ['xag', '白银', '国际银']),
        // 宏观（P0 仅作标签，行情可空）
        DictEntry('DXY', AssetClass.macro, ['dxy', '美元指数']),
        DictEntry('NDX', AssetClass.macro, ['ndx', '纳指', '纳斯达克指数']),
      ];
}
