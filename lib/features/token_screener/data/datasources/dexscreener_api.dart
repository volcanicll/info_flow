import 'package:dio/dio.dart';
import '../../domain/models/onchain_token.dart';

class DexScreenerApi {
  final Dio _dio;

  DexScreenerApi(this._dio);

  static const String _baseUrl = 'https://api.dexscreener.com';

  /// 搜索代币交易对（按 Symbol、名称或合约地址）
  Future<List<OnChainToken>> searchPairs(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/latest/dex/search',
        queryParameters: {'q': query.trim()},
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final pairs = resp.data?['pairs'] as List<dynamic>? ?? [];
      return pairs
          .whereType<Map<String, dynamic>>()
          .map(OnChainToken.fromDexScreenerPair)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 通过代币合约地址获取所属交易对
  Future<List<OnChainToken>> getPairsByTokenAddress(String address) async {
    if (address.trim().isEmpty) return [];
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/latest/dex/tokens/$address',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final pairs = resp.data?['pairs'] as List<dynamic>? ?? [];
      return pairs
          .whereType<Map<String, dynamic>>()
          .map(OnChainToken.fromDexScreenerPair)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取 DexScreener Top Boosts / 热门代币
  Future<List<Map<String, dynamic>>> getTopBoosts() async {
    try {
      final resp = await _dio.get<dynamic>(
        '$_baseUrl/token-boosts/top/v1',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      if (resp.data is List) {
        return (resp.data as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// 获取指定链的高流动性热门代币对
  Future<List<OnChainToken>> getTrendingByChain(ChainType chain) async {
    final query = switch (chain) {
      ChainType.solana => 'SOL',
      ChainType.base => 'BASE',
      ChainType.bsc => 'BNB',
      ChainType.robinhood => 'robinhood',
    };

    final results = await searchPairs(query);
    // 精准过滤匹配该链
    final filtered = results.where((t) => t.chain == chain).toList();
    // 按 24h 交易量与流动性综合降序
    filtered.sort((a, b) => b.volume24h.compareTo(a.volume24h));
    return filtered;
  }
}
