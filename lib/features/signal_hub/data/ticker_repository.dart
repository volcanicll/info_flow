import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../feed/presentation/controllers/article_cache.dart';
import '../../crypto_radar/data/datasources/binance_api.dart';
import '../domain/entities/ticker_quote.dart';
import '../domain/entities/ticker_ref.dart';

part 'ticker_repository.g.dart';

/// 链上行情仓库：以加密市场为核心（Binance 合约/现货及聚合源），
/// 对外统一以 symbol（大写）为键返回 TickerQuote。
///
/// 设计原则：任一源失败不得影响其它源；缺数据的 symbol 静默丢弃。
class TickerRepository {
  TickerRepository(this._crypto);

  final BinanceApi _crypto;

  /// 仅用于测试：允许注入假源。
  @visibleForTesting
  TickerRepository.forTest({
    required BinanceApi crypto,
    dynamic metals, // 向后兼容旧测试签名
  }) : this(crypto);

  /// 获取给定 symbol 集合的报价。未命中的 symbol 不出现在结果中。
  Future<Map<String, TickerQuote>> fetchQuotes(Set<String> symbols) async {
    final result = <String, TickerQuote>{};
    if (symbols.isEmpty) return result;

    final upper = symbols.map((s) => s.toUpperCase()).toSet();
    final cryptoSyms = <String>[];
    for (final s in upper) {
      cryptoSyms.add('${s}USDT'); // 统一映射到 USDT 交易对
    }

    // 加密：并行取所有 symbol 的 24h 报价或 K 线，任一失败不影响其它
    try {
      final results = await Future.wait(
        cryptoSyms.map((sym) => _crypto.getTicker24hSingle(sym).then((data) {
          if (data == null) return null;
          final lastPrice = _n(data['lastPrice']);
          final change = _n(data['priceChangePercent']);
          if (lastPrice <= 0) return null;
          final coin = sym.replaceAll('USDT', '');
          return MapEntry(coin, TickerQuote(
            symbol: coin,
            asset: AssetClass.crypto,
            price: lastPrice,
            changePercent: change,
          ));
        }).catchError((_) => null)),
      );
      for (final entry in results) {
        if (entry != null) result[entry.key] = entry.value;
      }
    } catch (_) {
      // 降级：忽略失败
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
TickerRepository tickerRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  final crypto = BinanceApi(dio);
  return TickerRepository(crypto);
}

@riverpod
Future<Map<String, TickerQuote>> tickerQuotes(Ref ref) {
  final cache = ref.watch(articleCacheProvider);
  final syms = <String>{};
  for (final a in cache.values) {
    for (final t in a.tickers) {
      syms.add(t.symbol);
    }
  }
  return ref.watch(tickerRepositoryProvider).fetchQuotes(syms);
}
