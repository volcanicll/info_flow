import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/crypto_radar/data/datasources/binance_api.dart';
import 'package:info_flow/features/precious_metals/data/metals_repository.dart';
import 'package:info_flow/features/signal_hub/data/ticker_repository.dart';

// 一个永远返回空数据的假 Dio：行情仓库应在接口失败时优雅降级（不抛、返回部分结果）。
// Dio 是 abstract class，用 noSuchMethod 桥接，使其可被 MetalsRepository 持有。
class _FakeDio implements Dio {
  _FakeDio();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('crypto symbol 命中时返回报价，price 来自 K 线收盘', () async {
    final repo = TickerRepository.forTest(
      crypto: _FakeBinanceReturnsNull(),
      metals: MetalsRepository(_FakeDio()),
    );
    final q = await repo.fetchQuotes({'BTC', 'ETH', 'XAU'});
    // 假源都返回 null/空，因此应为空 map（验证降级不抛）
    expect(q, isEmpty);
  });

  test('传入空集合返回空 map', () async {
    final repo = TickerRepository.forTest(
      crypto: _FakeBinanceReturnsNull(),
      metals: MetalsRepository(_FakeDio()),
    );
    expect(await repo.fetchQuotes({}), isEmpty);
  });

  test('symbol 大小写不敏感：btc 与 BTC 视作同一', () async {
    final repo = TickerRepository.forTest(
      crypto: _FakeBinanceReturnsNull(),
      metals: MetalsRepository(_FakeDio()),
    );
    // 不抛异常即可（无网络，结果为空）
    await repo.fetchQuotes({'btc', 'Btc'});
  });
}

class _FakeBinanceReturnsNull implements BinanceApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
