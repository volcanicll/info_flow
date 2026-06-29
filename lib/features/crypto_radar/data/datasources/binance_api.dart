import 'package:dio/dio.dart';

class BinanceApi {
  final Dio _dio;

  BinanceApi(this._dio);

  static const _fapi = 'https://fapi.binance.com';

  Future<Map<String, dynamic>?> _get(String path, {Map<String, dynamic>? params}) async {
    try {
      final resp = await _dio.get<dynamic>('$_fapi$path', queryParameters: params);
      if (resp.statusCode == 200) return resp.data as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> _getList(String path, {Map<String, dynamic>? params}) async {
    try {
      final resp = await _dio.get<dynamic>('$_fapi$path', queryParameters: params);
      if (resp.statusCode == 200 && resp.data is List) return resp.data as List<dynamic>;
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _getRaw(String url) async {
    try {
      final resp = await _dio.get<dynamic>(url);
      if (resp.statusCode == 200 && resp.data is Map) return resp.data as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<List<String>> getAllPerpSymbols() async {
    final info = await _get('/fapi/v1/exchangeInfo');
    if (info == null) return [];
    final symbols = info['symbols'] as List<dynamic>? ?? [];
    return symbols
        .where((s) =>
            s['quoteAsset'] == 'USDT' &&
            s['contractType'] == 'PERPETUAL' &&
            s['status'] == 'TRADING')
        .map<String>((s) => s['symbol'] as String)
        .toList();
  }

  Future<List<List<dynamic>>?> getKlines(String symbol, {int limit = 180}) async {
    final data = await _getList('/fapi/v1/klines', params: {
      'symbol': symbol,
      'interval': '1d',
      'limit': limit,
    });
    if (data == null) return null;
    return data.cast<List<dynamic>>();
  }

  Future<List<Map<String, dynamic>>?> getTicker24h() async {
    final data = await _getList('/fapi/v1/ticker/24hr');
    if (data == null) return null;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getTicker24hSingle(String symbol) async {
    return await _get('/fapi/v1/ticker/24hr', params: {'symbol': symbol});
  }

  Future<List<Map<String, dynamic>>?> getPremiumIndex() async {
    final data = await _getList('/fapi/v1/premiumIndex');
    if (data == null) return null;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>?> getOpenInterestHist(String symbol, {int limit = 6}) async {
    final data = await _getList('/futures/data/openInterestHist', params: {
      'symbol': symbol,
      'period': '1h',
      'limit': limit,
    });
    if (data == null) return null;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>?> getFundingRate(String symbol, {int limit = 5}) async {
    final data = await _getList('/fapi/v1/fundingRate', params: {
      'symbol': symbol,
      'limit': limit,
    });
    if (data == null) return null;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getBinanceMarketList() async {
    return await _getRaw('https://www.binance.com/bapi/composite/v1/public/marketing/symbol/list');
  }

  Future<List<Map<String, dynamic>>?> getCoinGeckoTrending() async {
    try {
      final resp = await _dio.get<dynamic>('https://api.coingecko.com/api/v3/search/trending');
      if (resp.statusCode == 200 && resp.data is Map) {
        final coins = (resp.data as Map)['coins'] as List<dynamic>?;
        if (coins != null) return coins.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }
}
