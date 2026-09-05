import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:info_flow/core/network/api_client.dart';

import '../domain/models/market_quote.dart';

class MarketRepository {
  MarketRepository(this._dio);

  final Dio _dio;

  Future<List<MarketQuote>> fetchCryptoQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return [];

    final results = await Future.wait(
      symbols.map((sym) async {
        try {
          final resp = await _dio.get<Map<String, dynamic>>(
            'https://api.binance.com/api/v3/ticker/24hr',
            queryParameters: {'symbol': '${sym}USDT'},
            options: Options(receiveTimeout: const Duration(seconds: 8)),
          );
          final data = resp.data;
          if (data == null) return null;
          final lastPrice = double.tryParse(data['lastPrice']?.toString() ?? '');
          final changePct =
              double.tryParse(data['priceChangePercent']?.toString() ?? '');
          final vol = double.tryParse(data['quoteVolume']?.toString() ?? '');
          if (lastPrice == null || lastPrice <= 0) return null;
          return MarketQuote(
            symbol: sym.toUpperCase(),
            name: sym.toUpperCase(),
            market: MarketType.crypto,
            price: lastPrice,
            changePercent: changePct ?? 0,
            volume: vol ?? 0,
            updatedAt: DateTime.now(),
          );
        } catch (_) {
          return null;
        }
      }),
    );

    return results.whereType<MarketQuote>().toList();
  }

  Future<Map<MarketType, List<MarketQuote>>> fetchMarketOverview() async {
    final cryptoQuotes = await fetchCryptoQuotes([
      'BTC',
      'ETH',
      'SOL',
      'BNB',
      'DOGE',
      'PEPE',
      'AVAX',
      'LINK',
      'UNI',
      'SUI',
    ]);

    return {
      MarketType.crypto: cryptoQuotes,
      MarketType.cnStock: const [],
      MarketType.usStock: const [],
      MarketType.hkStock: const [],
    };
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(ref.watch(dioProvider));
});
