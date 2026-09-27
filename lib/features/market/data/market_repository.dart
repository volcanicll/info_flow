import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:info_flow/core/network/api_client.dart';

import '../domain/models/market_quote.dart';

class MarketRepository {
  MarketRepository(this._dio);

  final Dio _dio;

  /// Binance 现货公共行情镜像（官方 data-api.binance.vision）：
  /// 与 api.binance.com 的 /api/v3/* 路径、响应完全一致，但不受区域封锁。
  static const _spotBase = 'https://data-api.binance.vision';

  Future<List<MarketQuote>> fetchCryptoQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return [];

    final results = await Future.wait(
      symbols.map((sym) async {
        try {
          final resp = await _dio.get<Map<String, dynamic>>(
            '$_spotBase/api/v3/ticker/24hr',
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

  /// 批量拉取现价（Binance 现货 /ticker/price，一次请求覆盖全部 symbol）。
  /// 返回 key = 基础币种大写；未上架 Binance 的币种不在结果中。
  /// 批量请求失败时逐个兜底，单个失败不拖垮其余。
  Future<Map<String, double>> fetchLastPrices(List<String> symbols) async {
    final base = symbols
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (base.isEmpty) return {};

    try {
      final resp = await _dio.get<List<dynamic>>(
        '$_spotBase/api/v3/ticker/price',
        // Binance 要求 JSON 数组形式（dio 默认会把 List 编码成重复 key）
        queryParameters: {
          'symbols': jsonEncode(base.map((s) => '${s}USDT').toList()),
        },
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final data = resp.data;
      if (data != null && data.isNotEmpty) {
        final out = <String, double>{};
        for (final row in data) {
          if (row is! Map) continue;
          final sym = row['symbol']?.toString() ?? '';
          final price = double.tryParse(row['price']?.toString() ?? '');
          if (sym.length <= 4 || !sym.endsWith('USDT')) continue;
          if (price == null || price <= 0) continue;
          out[sym.substring(0, sym.length - 4)] = price;
        }
        if (out.isNotEmpty) return out;
      }
    } catch (_) {
      // 批量接口失败（含任一 symbol 无效导致整批报错）：走逐个兜底
    }

    final out = <String, double>{};
    await Future.wait(base.map((s) async {
      try {
        final resp = await _dio.get<Map<String, dynamic>>(
          '$_spotBase/api/v3/ticker/price',
          queryParameters: {'symbol': '${s}USDT'},
          options: Options(receiveTimeout: const Duration(seconds: 8)),
        );
        final price = double.tryParse(resp.data?['price']?.toString() ?? '');
        if (price != null && price > 0) out[s] = price;
      } catch (_) {}
    }));
    return out;
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
