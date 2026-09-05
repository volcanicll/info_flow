import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/network/api_client.dart';
import '../../../crypto_radar/presentation/controllers/crypto_radar_controller.dart';
import '../../../token_screener/data/repositories/token_screener_repository.dart';
import '../../../token_screener/domain/models/onchain_token.dart';

part 'coin_detail_controller.g.dart';

/// 币种详情页状态：24h 报价 + K 线序列 + 资金费率 + OI 历史 + GoPlus 安全审计。
class CoinDetailState {
  final bool loading;
  final String? error;

  /// 当前价 / 24h 涨跌% / 24h 成交额（美元）
  final double? price;
  final double? changePercent;
  final double? volume;

  /// 最近 K 线收盘价序列（时间升序），用于迷你图
  final List<double> closes;

  /// 最近资金费率序列（升序）
  final List<double> fundingRates;

  /// 最近持仓量（美元）序列（升序）
  final List<double> openInterest;

  /// 链上安全审计
  final TokenSecurity? security;

  /// 链上 DEX 代币详情
  final OnChainToken? onchainToken;

  const CoinDetailState({
    this.loading = false,
    this.error,
    this.price,
    this.changePercent,
    this.volume,
    this.closes = const [],
    this.fundingRates = const [],
    this.openInterest = const [],
    this.security,
    this.onchainToken,
  });

  CoinDetailState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    double? price,
    double? changePercent,
    double? volume,
    List<double>? closes,
    List<double>? fundingRates,
    List<double>? openInterest,
    TokenSecurity? security,
    OnChainToken? onchainToken,
  }) {
    return CoinDetailState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      volume: volume ?? this.volume,
      closes: closes ?? this.closes,
      fundingRates: fundingRates ?? this.fundingRates,
      openInterest: openInterest ?? this.openInterest,
      security: security ?? this.security,
      onchainToken: onchainToken ?? this.onchainToken,
    );
  }
}

@riverpod
class CoinDetail extends _$CoinDetail {
  @override
  CoinDetailState build(String symbol) => const CoinDetailState();

  /// 加载指定币种（如 SOL）的详情，支持指定 CA 地址和链类型
  Future<void> load({String? address, String? chainId}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(binanceApiProvider);
      final screenerRepo = ref.read(tokenScreenerRepositoryProvider);

      final sym = '${symbol}USDT';
      final ticker = await api.getTicker24hSingle(sym);
      final klines = await api.getKlines(sym, interval: '1h', limit: 48);
      final funding = await api.getFundingRate(sym, limit: 12);
      final oiHist = await api.getOpenInterestHist(sym, limit: 12);

      double? price;
      double? change;
      double? vol;
      if (ticker != null) {
        price = _n(ticker['lastPrice']);
        change = _n(ticker['priceChangePercent']);
        vol = _n(ticker['quoteVolume']);
      }

      // 如果有合约地址或为链上代币，进行 DexScreener 与 GoPlus 安全检索
      TokenSecurity? sec;
      OnChainToken? oct;

      final targetChain = ChainType.fromId(chainId);
      final targetAddr = address ?? '';

      if (targetAddr.isNotEmpty) {
        final profile = await screenerRepo.getTokenProfile(
          chain: targetChain,
          address: targetAddr,
        );
        oct = profile.token;
        sec = profile.security;
      } else {
        // 通过 symbol 进行全网检索以补充流动性与安全体检
        final searchResults = await screenerRepo.searchTokens(symbol);
        if (searchResults.isNotEmpty) {
          oct = searchResults.first;
          sec = await ref.read(goPlusApiProvider).checkSecurity(oct.chain, oct.address);
        }
      }

      // 若 CEX 接口未命中，回退至 DEX 价格与成交量
      if ((price == null || price <= 0) && oct != null) {
        price = oct.priceUsd;
        change = oct.priceChange24h;
        vol = oct.volume24h;
      }

      state = state.copyWith(
        loading: false,
        price: price,
        changePercent: change,
        volume: vol,
        closes: (klines ?? []).map((k) => _n(k[4])).toList(),
        fundingRates: (funding ?? [])
            .map((f) => _n(f['fundingRate']))
            .toList(),
        openInterest: (oiHist ?? [])
            .map((o) => _n(o['sumOpenInterestValue']))
            .toList(),
        security: sec ?? TokenSecurity.safeDefault(),
        onchainToken: oct,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: mapToAppException(e).message,
      );
    }
  }

  double _n(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
