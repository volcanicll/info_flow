import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<List<MarketQuote>> fetchStockQuotes(
    MarketType market,
    List<String> codes,
  ) async {
    if (codes.isEmpty) return [];

    final prefix = switch (market) {
      MarketType.cnStock => '',
      MarketType.usStock => 'gb_',
      MarketType.hkStock => 'rt_hk',
      MarketType.crypto => '',
    };

    final listParam = codes.map((c) => '$prefix$c').join(',');

    try {
      final resp = await _dio.get<String>(
        'https://hq.sinajs.cn/list=$listParam',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Referer': 'https://finance.sina.com.cn/',
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          },
        ),
      );

      final body = resp.data;
      if (body == null || body.isEmpty) return [];

      final results = <MarketQuote>[];
      final regex = RegExp(r'var hq_str_(\w+)="([^"]+)";');
      final now = DateTime.now();

      for (final match in regex.allMatches(body)) {
        final rawCode = match.group(1)!;
        final data = match.group(2)!.split(',');

        String? name;
        double? current;
        double? prevClose;
        double volume = 0;

        switch (market) {
          case MarketType.cnStock:
            if (data.length < 10) continue;
            name = data[0];
            prevClose = double.tryParse(data[2]);
            current = double.tryParse(data[3]);
            volume = double.tryParse(data[9]) ?? 0;
          case MarketType.usStock:
            if (data.length < 9) continue;
            name = data[0];
            current = double.tryParse(data[1]);
            prevClose = double.tryParse(data[5]);
            volume = double.tryParse(data[8]) ?? 0;
          case MarketType.hkStock:
            if (data.length < 7) continue;
            name = data[0];
            prevClose = double.tryParse(data[2]);
            current = double.tryParse(data[3]);
            volume = double.tryParse(data[6]) ?? 0;
          case MarketType.crypto:
            continue;
        }

        if (current == null || current <= 0) continue;
        if (prevClose == null || prevClose <= 0) {
          prevClose = current;
        }

        final changePct = ((current - prevClose) / prevClose) * 100;

        final symbol = switch (market) {
          MarketType.cnStock => _parseCnStockSymbol(rawCode),
          MarketType.usStock => rawCode.replaceFirst('gb_', '').toUpperCase(),
          MarketType.hkStock => '${rawCode.replaceFirst('rt_hk', '')}.HK',
          MarketType.crypto => rawCode,
        };

        results.add(MarketQuote(
          symbol: symbol,
          name: name,
          market: market,
          price: current,
          changePercent: changePct,
          volume: volume,
          updatedAt: now,
        ));
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  Future<Map<MarketType, List<MarketQuote>>> fetchMarketOverview() async {
    final results = await Future.wait([
      fetchCryptoQuotes(['BTC', 'ETH', 'SOL', 'BNB']),
      fetchStockQuotes(MarketType.cnStock, [
        'sh000001',
        'sz399001',
        'sz399006',
        'sh000688',
        'sh000300',
      ]),
      fetchStockQuotes(MarketType.usStock, [
        'aapl',
        'msft',
        'goog',
        'nvda',
        'amzn',
        'meta',
        'tsla',
      ]),
      fetchStockQuotes(MarketType.hkStock, ['00700', '09988', '03690']),
    ]);

    return {
      MarketType.crypto: results[0],
      MarketType.cnStock: results[1],
      MarketType.usStock: results[2],
      MarketType.hkStock: results[3],
    };
  }

  String _parseCnStockSymbol(String raw) {
    final prefix = raw.substring(0, 2).toUpperCase();
    final numPart = raw.substring(2);
    return '$numPart.$prefix';
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return MarketRepository(dio);
});
