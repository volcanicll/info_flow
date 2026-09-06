import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:info_flow/core/network/api_client.dart';
import 'crypto_watchlist_store.dart';

import 'datasources/binance_api.dart';
import 'models/watch_quote.dart';

/// 自选币实时报价（24h 涨跌，Binance 全量一次拉取再过滤）。
///
/// watch [cryptoWatchlistStoreProvider]：加星/去星即刻联动刷新。
/// 为避免每次 toggle 都触发一次全市场拉取（数百币），报价带 TTL 缓存：
/// 窗口内复用上次结果并过滤出当前自选，超时才重新拉取。
final watchlistQuotesProvider = FutureProvider<Map<String, WatchQuote>>((ref) async {
  final watchlist = ref.watch(cryptoWatchlistStoreProvider);
  if (watchlist.isEmpty) return const {};

  final now = DateTime.now();
  if (_cache != null &&
      now.difference(_cacheAt!) < _ttl &&
      watchlist.every(_cache!.containsKey)) {
    // 缓存有效且覆盖全部自选：直接过滤复用，避免闪烁与重拉
    return {
      for (final coin in watchlist)
        if (_cache!.containsKey(coin)) coin: _cache![coin]!,
    };
  }

  final api = BinanceApi(ref.watch(dioProvider));
  final all = await api.getTicker24h();
  if (all == null) return const {};

  final result = <String, WatchQuote>{};
  for (final t in all) {
    final sym = t['symbol'] as String? ?? '';
    if (!sym.endsWith('USDT')) continue;
    final coin = sym.replaceAll('USDT', '');
    if (!watchlist.contains(coin)) continue;

    final price = _n(t['lastPrice']);
    final pxChg = _n(t['priceChangePercent']);
    final vol = _n(t['quoteVolume']);
    if (price <= 0) continue;
    result[coin] = WatchQuote(
      coin: coin,
      price: price,
      changePercent: pxChg,
      volume: vol,
    );
  }

  _cache = result;
  _cacheAt = now;
  return result;
});

const _ttl = Duration(seconds: 15);
DateTime? _cacheAt;
Map<String, WatchQuote>? _cache;

double _n(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
