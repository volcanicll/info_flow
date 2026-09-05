import '../domain/entities/ticker_ref.dart';

/// 词典单条：一个标的 + 它的若干匹配别名（已小写、去标点）。
class DictEntry {
  final String symbol;
  final AssetClass asset;
  final List<String> aliases;
  const DictEntry(this.symbol, this.asset, this.aliases);
}

/// 链上标的词典：专注于 Solana, Base, BSC, Robinhood 及主流加密核心标的。
class TickerDictionary {
  TickerDictionary._();
  static final TickerDictionary instance = TickerDictionary._();
  factory TickerDictionary() => instance;

  List<DictEntry> get entries => const [
        // ── Solana 生态标的 ──
        DictEntry('SOL', AssetClass.crypto, ['sol', '索拉纳', 'solana', 'sol币']),
        DictEntry('JUP', AssetClass.crypto, ['jup', 'jupiter', '木星']),
        DictEntry('RAY', AssetClass.crypto, ['ray', 'raydium']),
        DictEntry('PYTH', AssetClass.crypto, ['pyth', '预言机pyth']),
        DictEntry('JTO', AssetClass.crypto, ['jto', 'jito']),
        DictEntry('BONK', AssetClass.crypto, ['bonk']),
        DictEntry('WIF', AssetClass.crypto, ['wif', 'dogwifhat']),
        DictEntry('POPCAT', AssetClass.crypto, ['popcat']),
        DictEntry('PUMP', AssetClass.crypto, ['pump', 'pumpfun', 'pump.fun']),

        // ── Base 生态标的 ──
        DictEntry('AERO', AssetClass.crypto, ['aero', 'aerodrome']),
        DictEntry('VIRTUAL', AssetClass.crypto, ['virtual', 'virtuals', '虚拟协议']),
        DictEntry('CLANKER', AssetClass.crypto, ['clanker']),
        DictEntry('BRETT', AssetClass.crypto, ['brett']),
        DictEntry('DEGEN', AssetClass.crypto, ['degen']),

        // ── BSC (BNB Chain) 生态标的 ──
        DictEntry('BNB', AssetClass.crypto, ['bnb', '币安币', 'binance coin']),
        DictEntry('CAKE', AssetClass.crypto, ['cake', 'pancakeswap', '薄饼']),
        DictEntry('BAKE', AssetClass.crypto, ['bake', 'bakeryswap']),
        DictEntry('TWT', AssetClass.crypto, ['twt', 'trust wallet']),
        DictEntry('FOUR', AssetClass.crypto, ['four', 'four.meme']),

        // ── Robinhood 生态及官方支持重点标的 ──
        DictEntry('HOOD', AssetClass.crypto, ['hood', 'robinhood', '罗宾汉']),
        DictEntry('BTC', AssetClass.crypto, ['btc', '比特币', '大饼', 'bitcoin']),
        DictEntry('ETH', AssetClass.crypto, ['eth', '以太坊', '以太', 'ethereum']),
        DictEntry('DOGE', AssetClass.crypto, ['doge', '狗狗币', 'dogecoin']),
        DictEntry('SHIB', AssetClass.crypto, ['shib', '柴犬币', 'shiba']),
        DictEntry('PEPE', AssetClass.crypto, ['pepe', '佩佩']),
        DictEntry('AVAX', AssetClass.crypto, ['avax', '雪崩', 'avalanche']),
        DictEntry('LINK', AssetClass.crypto, ['link', 'chainlink']),
        DictEntry('UNI', AssetClass.crypto, ['uni', 'uniswap']),
        DictEntry('SUI', AssetClass.crypto, ['sui', 'sui network']),
        DictEntry('XRP', AssetClass.crypto, ['xrp', '瑞波', 'ripple']),
      ];
}
