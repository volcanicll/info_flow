import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/dexscreener_api.dart';
import '../datasources/goplus_api.dart';
import '../../domain/models/onchain_token.dart';

class TokenScreenerRepository {
  final DexScreenerApi _dexApi;
  final GoPlusApi _goPlusApi;

  TokenScreenerRepository(this._dexApi, this._goPlusApi);

  /// 搜索代币（名称、Symbol 或 CA 地址）
  Future<List<OnChainToken>> searchTokens(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    // 若输入看似以太坊或 Solana 地址，优先查 Token 详情
    if (clean.startsWith('0x') || clean.length >= 32) {
      final byAddr = await _dexApi.getPairsByTokenAddress(clean);
      if (byAddr.isNotEmpty) return byAddr;
    }

    return await _dexApi.searchPairs(clean);
  }

  /// 获取指定代币完整画像：行情 + GoPlus 链上安全审计
  Future<({OnChainToken? token, TokenSecurity security})> getTokenProfile({
    required ChainType chain,
    required String address,
  }) async {
    final pairs = await _dexApi.getPairsByTokenAddress(address);
    final token = pairs.isNotEmpty ? pairs.first : null;
    final security = await _goPlusApi.checkSecurity(chain, address);

    return (token: token, security: security);
  }

  /// 获取指定生态链的热门交易对
  Future<List<OnChainToken>> getTrendingTokens(ChainType chain) async {
    return await _dexApi.getTrendingByChain(chain);
  }
}

final dexScreenerApiProvider = Provider<DexScreenerApi>((ref) {
  return DexScreenerApi(ref.watch(dioProvider));
});

final goPlusApiProvider = Provider<GoPlusApi>((ref) {
  return GoPlusApi(ref.watch(dioProvider));
});

final tokenScreenerRepositoryProvider = Provider<TokenScreenerRepository>((ref) {
  return TokenScreenerRepository(
    ref.watch(dexScreenerApiProvider),
    ref.watch(goPlusApiProvider),
  );
});
