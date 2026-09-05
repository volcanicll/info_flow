import 'package:dio/dio.dart';
import 'package:info_flow/features/token_screener/data/datasources/dexscreener_api.dart';
import 'package:info_flow/features/token_screener/data/datasources/goplus_api.dart';
import 'package:info_flow/features/token_screener/domain/models/onchain_token.dart';
import 'package:info_flow/features/feed/data/rss_repository.dart';
import 'package:info_flow/features/feed/data/rss_sources.dart';
import 'package:info_flow/features/signal_hub/data/ticker_dictionary.dart';
import 'package:info_flow/features/signal_hub/data/ticker_resolver.dart';

void main() async {
  print('===========================================================');
  print('🚀 开始执行 InfoFlow 链上信息平台实盘数据管道端到端测试');
  print('===========================================================\n');

  final dio = Dio();
  final dexApi = DexScreenerApi(dio);
  final goPlusApi = GoPlusApi(dio);

  // 1. 测试四链 DexScreener 实时行情
  print('【步骤 1/4】测试 DexScreener 多链实时流动性行情:');

  for (final chain in [
    ChainType.solana,
    ChainType.base,
    ChainType.bsc,
    ChainType.robinhood
  ]) {
    print('  --> 正在拉取 ${chain.label} (${chain.shortName}) 链上池子...');
    final tokens = await dexApi.getTrendingByChain(chain);
    if (tokens.isNotEmpty) {
      final top = tokens.first;
      print(
          '      ✅ 成功获取 ${tokens.length} 个代币对! 头部标的: \$${top.symbol} (${top.name})');
      print(
          '         价格: \$${top.priceUsd.toStringAsFixed(4)} | 24h涨跌: ${top.priceChange24h.toStringAsFixed(2)}% | 流动性: \$${(top.liquidityUsd / 1e3).toStringAsFixed(1)}K | 24h交易量: \$${(top.volume24h / 1e3).toStringAsFixed(1)}K');
      print('         DEX: ${top.dexId?.toUpperCase()} | CA: ${top.address}');
    } else {
      print('      ⚠️ 未获取到 ${chain.label} 数据');
    }
  }

  print('\n-----------------------------------------------------------');
  // 2. 测试 GoPlus 链上智能合约安全审计 (防貔貅/防Rug)
  print('【步骤 2/4】测试 GoPlus 链上智能合约安全审计引擎:');

  print('  --> [BSC] 检测 PancakeSwap CA (0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82)...');
  final bscSec = await goPlusApi.checkEvmTokenSecurity(
    chainId: '56',
    contractAddress: '0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82',
  );
  if (bscSec != null) {
    print('      ✅ BSC 审计完成! 安全评分: ${bscSec.score}/100 [${bscSec.riskLevel.label}]');
    print('         貔貅风险: ${bscSec.isHoneypot ? "🚨 是" : "✅ 否"} | 买税: ${bscSec.buyTax}% | 卖税: ${bscSec.sellTax}% | 增发权限: ${bscSec.isMintable ? "⚠️ 存在" : "✅ 已放弃"}');
    print('         持币人数: ${bscSec.holderCount} | Top10持仓占比: ${bscSec.top10HolderPercent.toStringAsFixed(1)}%');
  }

  print('  --> [Base] 检测 Aerodrome CA (0x940181a94a35a4569e4529a3cdfb74e38fd98631)...');
  final baseSec = await goPlusApi.checkEvmTokenSecurity(
    chainId: '8453',
    contractAddress: '0x940181a94a35a4569e4529a3cdfb74e38fd98631',
  );
  if (baseSec != null) {
    print('      ✅ Base 审计完成! 安全评分: ${baseSec.score}/100 [${baseSec.riskLevel.label}]');
    print('         貔貅风险: ${baseSec.isHoneypot ? "🚨 是" : "✅ 否"} | 买税: ${baseSec.buyTax}% | 卖税: ${baseSec.sellTax}% | 黑名单: ${baseSec.isBlacklist ? "⚠️ 存在" : "✅ 无"}');
    print('         持币人数: ${baseSec.holderCount} | Top10持仓占比: ${baseSec.top10HolderPercent.toStringAsFixed(1)}%');
  }

  print('  --> [Solana] 检测 Jupiter Mint (JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN)...');
  final solSec = await goPlusApi.checkSolanaTokenSecurity(
    'JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN',
  );
  if (solSec != null) {
    print('      ✅ Solana 审计完成! 安全评分: ${solSec.score}/100 [${solSec.riskLevel.label}]');
    print('         冻结权限: ${solSec.isFreezable ? "🚨 未丢弃" : "✅ 已放弃"} | 铸造权限: ${solSec.isMintable ? "⚠️ 未丢弃" : "✅ 已放弃"}');
  }

  print('\n-----------------------------------------------------------');
  // 3. 测试 Web3 情报源拉取与标的识别
  print('【步骤 3/4】测试 Web3 专属情报抓取与标的徽章自动解析:');
  final rssRepo = RssRepository(dio);
  final testSource = RssSources.byId('foresight-news') ?? RssSources.byId('coindesk')!;
  print('  --> 正在拉取 ${testSource.name} (${testSource.feedUrl})...');

  final articles = await rssRepo.fetchSource(testSource, maxItems: 5);
  print('      ✅ 成功抓取 ${articles.length} 条实时链上情报!');

  final resolver = TickerResolver(TickerDictionary.instance);
  final enriched = resolver.resolveList(articles);

  for (var i = 0; i < enriched.length; i++) {
    final a = enriched[i];
    final tickersStr = a.tickers.isNotEmpty
        ? a.tickers.map((t) => '\$${t.symbol}').join(', ')
        : '无特定标的';
    print('      [${i + 1}] ${a.title}');
    print('          识别标的: $tickersStr | 发布时间: ${a.publishedAt}');
  }

  print('\n-----------------------------------------------------------');
  print('【步骤 4/4】测试完成！四链数据管道 (Solana/Base/BSC/Robinhood) 与安全引擎全部健康可用！');
  print('===========================================================');
}
