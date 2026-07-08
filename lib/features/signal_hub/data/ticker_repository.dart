import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/article_cache.dart';
import '../../crypto_radar/data/datasources/binance_api.dart';
import '../../precious_metals/data/metals_repository.dart';
import '../domain/entities/ticker_quote.dart';
import '../domain/entities/ticker_ref.dart';

part 'ticker_repository.g.dart';

/// 行情仓库：聚合 crypto（Binance）与 metals（新浪）两个数据源，
/// 对外统一以 symbol（大写）为键返回 TickerQuote。
///
/// 设计原则：任一源失败不得影响其它源；缺数据的 symbol 静默丢弃。
class TickerRepository {
  TickerRepository(this._crypto, this._metals);

  final BinanceApi _crypto;
  final MetalsRepository _metals;

  /// 仅用于测试：允许注入假源。
  @visibleForTesting
  TickerRepository.forTest({
    required this._crypto,
    required this._metals,
  });

  /// 获取给定 symbol 集合的报价。未命中的 symbol 不出现在结果中。
  Future<Map<String, TickerQuote>> fetchQuotes(Set<String> symbols) async {
    final result = <String, TickerQuote>{};
    if (symbols.isEmpty) return result;

    final upper = symbols.map((s) => s.toUpperCase()).toSet();
    final cryptoSyms = <String>[];
    final metalSyms = <String>{};
    for (final s in upper) {
      // 资产类只能从词典推断；此处简化：已知 metal symbol 集合
      if (const {'XAU', 'XAG'}.contains(s)) {
        metalSyms.add(s);
      } else {
        cryptoSyms.add('${s}USDT'); // Binance 永续合约命名
      }
    }

    // 加密：并行取所有 symbol 的 K 线，任一失败不影响其它
    try {
      final results = await Future.wait(
        cryptoSyms.map((sym) => _crypto.getKlines(sym, limit: 2).then((klines) {
          if (klines == null || klines.length < 2) return null;
          final close = _n(klines.last[4]);
          final prevClose = _n(klines.first[4]);
          if (close <= 0 || prevClose <= 0) return null;
          final coin = sym.replaceAll('USDT', '');
          return MapEntry(coin, TickerQuote(
            symbol: coin,
            asset: AssetClass.crypto,
            price: close,
            changePercent: (close - prevClose) / prevClose * 100,
          ));
        }).catchError((_) => null)),
      );
      for (final entry in results) {
        if (entry != null) result[entry.key] = entry.value;
      }
    } catch (_) {
      // 降级：忽略加密源
    }

    // 贵金属：一次性拉全部，按 code 过滤
    try {
      final metals = await _metals.fetchPrices();
      for (final m in metals) {
        if (metalSyms.contains(m.code)) {
          result[m.code] = TickerQuote(
            symbol: m.code,
            asset: AssetClass.metal,
            price: m.price,
            changePercent: m.changePercent,
          );
        }
      }
    } catch (_) {
      // 降级：忽略金属源
    }

    return result;
  }

  double _n(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

@riverpod
TickerRepository tickerRepository(TickerRepositoryRef ref) {
  // 复用 core/network 已注册的共享 dioProvider（含统一拦截器/超时）。
  final dio = ref.watch(dioProvider);
  final crypto = BinanceApi(dio);
  final metals = MetalsRepository(dio);
  return TickerRepository(crypto, metals);
}

@riverpod
Future<Map<String, TickerQuote>> tickerQuotes(TickerQuotesRef ref) {
  final cache = ref.watch(articleCacheProvider);
  final syms = <String>{};
  for (final a in cache.values) {
    for (final t in a.tickers) {
      syms.add(t.symbol);
    }
  }
  return ref.watch(tickerRepositoryProvider).fetchQuotes(syms);
}
