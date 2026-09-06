import 'package:flutter_test/flutter_test.dart';

import 'package:info_flow/core/notifications/signal_dedup.dart';

void main() {
  group('diffFreshSignals', () {
    test('全部为新信号时全部返回', () {
      const incoming = ['BTC|long|85', 'ETH|long|72'];
      expect(diffFreshSignals(incoming, const []), incoming);
    });

    test('已见过的信号被过滤，仅返回新增', () {
      const incoming = ['BTC|long|85', 'ETH|long|72', 'SOL|short|66'];
      const seen = ['BTC|long|85', 'ETH|long|72'];
      expect(diffFreshSignals(incoming, seen), ['SOL|short|66']);
    });

    test('全部已见时返回空', () {
      const incoming = ['BTC|long|85'];
      const seen = ['BTC|long|85', 'ETH|long|72'];
      expect(diffFreshSignals(incoming, seen), isEmpty);
    });

    test('相同 coin 不同方向视为不同信号', () {
      const incoming = ['BTC|long|85', 'BTC|short|80'];
      const seen = ['BTC|long|85'];
      expect(diffFreshSignals(incoming, seen), ['BTC|short|80']);
    });

    test('incoming 内部重复时全部返回（内部去重由调用方写入 seen 后生效）', () {
      const incoming = ['BTC|long|85', 'BTC|long|85'];
      expect(diffFreshSignals(incoming, const []), incoming);
      // 写入 seen 后第二轮即视为已见
      expect(
        diffFreshSignals(incoming, ['BTC|long|85']),
        isEmpty,
      );
    });
  });
}
