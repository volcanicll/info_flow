import 'package:dio/dio.dart';
import '../../domain/models/onchain_token.dart';

class GoPlusApi {
  final Dio _dio;

  GoPlusApi(this._dio);

  static const String _baseUrl = 'https://api.gopluslabs.io';

  /// 检测 EVM 链代币安全（BSC: 56, Base: 8453）
  Future<TokenSecurity?> checkEvmTokenSecurity({
    required String chainId,
    required String contractAddress,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/v1/token_security/$chainId',
        queryParameters: {
          'contract_addresses': contractAddress.toLowerCase(),
        },
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final result = resp.data?['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      final tokenData = result[contractAddress.toLowerCase()] as Map<String, dynamic>?;
      if (tokenData == null) return null;
      return TokenSecurity.fromGoPlusEvm(tokenData);
    } catch (_) {
      return null;
    }
  }

  /// 检测 Solana 链代币安全（铸造权、冻结权、可关闭等）
  Future<TokenSecurity?> checkSolanaTokenSecurity(String mintAddress) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/v1/solana/token_security',
        queryParameters: {
          'contract_addresses': mintAddress,
        },
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final result = resp.data?['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      final tokenData = result[mintAddress] as Map<String, dynamic>?;
      if (tokenData == null) return null;
      return TokenSecurity.fromGoPlusSolana(tokenData);
    } catch (_) {
      return null;
    }
  }

  /// 统一安全检测接口（自动根据 ChainType 分流）
  Future<TokenSecurity> checkSecurity(ChainType chain, String address) async {
    TokenSecurity? sec;
    switch (chain) {
      case ChainType.bsc:
        sec = await checkEvmTokenSecurity(chainId: '56', contractAddress: address);
      case ChainType.base:
        sec = await checkEvmTokenSecurity(chainId: '8453', contractAddress: address);
      case ChainType.solana:
        sec = await checkSolanaTokenSecurity(address);
      case ChainType.robinhood:
        // Robinhood 官方生态合规标的默认为安全
        return TokenSecurity.safeDefault();
    }
    return sec ?? TokenSecurity.safeDefault();
  }
}
