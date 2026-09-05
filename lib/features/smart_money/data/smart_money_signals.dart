import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../token_screener/data/repositories/token_screener_repository.dart';
import '../../token_screener/domain/models/onchain_token.dart';
import 'models/rht_token.dart';
import 'smart_money_repository.dart';

/// 聪明钱信号融合层：把上游数据与 DexScreener / GoPlus 交叉验证，
/// 产出比原始流水更干净的可执行信号。

/// 共振门槛：DexScreener 流动性低于该值的聪明钱首买不入选
/// （上游 tape 不做过滤，貔貅盘/死池占比高，这里是质量闸门）。
const _minLiquidityUsd = 20000.0;

/// 代币聪明钱流的两种查询键：合约地址（Screener 用）与 symbol（Pulse 用）。
class SmartMoneyFlowIndex {
  final Map<String, RhtTokenFlow> byAddress;
  final Map<String, RhtTokenFlow> bySymbol;

  const SmartMoneyFlowIndex({
    required this.byAddress,
    required this.bySymbol,
  });

  /// 有被追踪钱包净买入的 symbol → 净流入额。
  Map<String, double> get netInflowBySymbol => {
        for (final e in bySymbol.entries)
          if (e.value.netUsd > 0) e.key: e.value.netUsd,
      };

  static const _empty = SmartMoneyFlowIndex(byAddress: {}, bySymbol: {});
}

/// 24h 聪明钱代币流索引：一次拉取，全 App 共享（60s 缓存语义由
/// FutureProvider 的重建策略保证——页面级 watch 不会反复请求）。
final smartMoneyFlowIndexProvider =
    FutureProvider.autoDispose<SmartMoneyFlowIndex>((ref) async {
  try {
    final flows = await ref.watch(smartMoneyRepositoryProvider).fetchTokenFlows();
    final byAddress = {
      for (final f in flows) f.token.toLowerCase(): f,
    };
    final bySymbol = {
      for (final f in flows) f.symbol.toUpperCase(): f,
    };
    return SmartMoneyFlowIndex(byAddress: byAddress, bySymbol: bySymbol);
  } catch (_) {
    return SmartMoneyFlowIndex._empty;
  }
});

/// 三源共振信号：聪明钱首买（上游 radar）∩ DexScreener 有效池子 ∩ GoPlus 审计。
class SmartResonance {
  final String symbol;
  final String name;
  final String address;
  final double usdIn;
  final int buyers;

  /// 首买大户 handle 与粉丝量（信号含金量）。
  final String firstBuyerHandle;
  final int firstBuyerFollowers;

  /// DexScreener 侧验证数据。
  final double liquidityUsd;
  final double? change24h;
  final String? pairUrl;

  const SmartResonance({
    required this.symbol,
    required this.name,
    required this.address,
    required this.usdIn,
    required this.buyers,
    required this.firstBuyerHandle,
    required this.firstBuyerFollowers,
    required this.liquidityUsd,
    required this.change24h,
    required this.pairUrl,
  });
}

final smartMoneyResonanceProvider =
    FutureProvider.autoDispose<List<SmartResonance>>((ref) async {
  final repo = ref.watch(smartMoneyRepositoryProvider);
  final dexApi = ref.watch(dexScreenerApiProvider);
  final goplus = ref.watch(goPlusApiProvider);

  final radar = await repo.fetchRadar(minutes: 120);
  if (radar.isEmpty) return const [];

  final results = <SmartResonance>[];  for (final item in radar.take(40)) {
    if (item.token.isEmpty || item.firstBuyer == null) continue;
    // 闸门一：DexScreener 存在有效池子且流动性达标
    final List<OnChainToken> pairs;
    try {
      pairs = await dexApi.getPairsByTokenAddress(item.token);
    } catch (_) {
      continue;
    }
    OnChainToken? best;
    for (final p in pairs) {
      if (p.liquidityUsd > (best?.liquidityUsd ?? 0)) best = p;
    }
    if (best == null || best.liquidityUsd < _minLiquidityUsd) continue;

    // 闸门二：GoPlus 审计（Robinhood 链按项目策略默认安全，
    // BSC/Base/Solana 走真实检测，貔貅直接剔除）
    try {
      final sec = await goplus.checkSecurity(best.chain, best.address);
      if (sec.isHoneypot) continue;
    } catch (_) {
      // 审计接口故障不阻塞信号，仅保留流动性闸门
    }

    results.add(SmartResonance(
      symbol: item.symbol,
      name: item.name,
      address: item.token,
      usdIn: item.usdIn,
      buyers: item.buyers,
      firstBuyerHandle: item.firstBuyer!.handle,
      firstBuyerFollowers: item.firstBuyer!.followers,
      liquidityUsd: best.liquidityUsd,
      change24h: best.priceChange24h,
      pairUrl: best.url,
    ));
  }
  // 首买粉丝量大的排前面（含金量优先）
  results.sort((a, b) => b.firstBuyerFollowers.compareTo(a.firstBuyerFollowers));
  return results;
});
