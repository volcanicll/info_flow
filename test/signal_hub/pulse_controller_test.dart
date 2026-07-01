import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/data/ticker_resolver.dart';
import 'package:info_flow/features/signal_hub/presentation/controllers/pulse_controller.dart';

void main() {
  test('PulseState 构造与字段', () {
    const s = PulseState(articles: [], quotes: {});
    expect(s.articles, isEmpty);
    expect(s.quotes, isEmpty);
  });

  test('TickerResolver 给空 Article 列表返回空', () {
    expect(TickerResolver().resolveList(const []), isEmpty);
  });
}
