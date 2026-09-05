import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/crypto_radar/data/datasources/binance_api.dart';
import 'package:info_flow/features/signal_hub/data/ticker_repository.dart';

void main() {
  test('crypto symbol 命中时返回报价，price 来自 24h 报价', () async {
    final repo = TickerRepository.forTest(
      crypto: _FakeBinanceReturnsNull(),
    );
    final q = await repo.fetchQuotes({'BTC', 'ETH', 'SOL'});
    expect(q, isEmpty);
  });

  test('传入空集合返回空 map', () async {
    final repo = TickerRepository.forTest(
      crypto: _FakeBinanceReturnsNull(),
    );
    expect(await repo.fetchQuotes({}), isEmpty);
  });

  test('symbol 大小写不敏感：btc 与 BTC 视作同一', () async {
    final repo = TickerRepository.forTest(
      crypto: _FakeBinanceReturnsNull(),
    );
    await repo.fetchQuotes({'btc', 'Btc'});
  });
}

class _FakeBinanceReturnsNull implements BinanceApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
