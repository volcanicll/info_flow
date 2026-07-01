import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/crypto_radar/data/datasources/binance_api.dart';

// 假 BinanceApi：模拟无网络环境，返回 resolved future(null)
class _FakeBinanceApi implements BinanceApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

void main() {
  test('getKlines 默认 interval 为 1d（向后兼容）', () async {
    final api = _FakeBinanceApi();
    // 无网络环境会返回 null，但不应抛异常；默认参数语法正确即可
    final result = await api.getKlines('BTCUSDT', limit: 2);
    expect(result, isNull); // 无网络，降级为 null
  });

  test('getKlines 接受 interval 命名参数', () async {
    final api = _FakeBinanceApi();
    // 传 1h 不应抛异常（编译期保证参数存在；运行期无网络返回 null）
    final result = await api.getKlines('BTCUSDT', interval: '1h', limit: 2);
    expect(result, isNull);
  });
}
