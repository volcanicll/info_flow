import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/signal_hub/data/ticker_resolver.dart';

void main() {
  final resolver = TickerResolver();

  Article _a(String title, {String? content}) => Article(
        id: 'x',
        feedId: 'f',
        feedName: 'n',
        title: title,
        url: 'https://example.com/x',
        content: content,
      );

  test('标题含 ETH，正文多次出现，返回 ETH 且 inTitle=true', () {
    final a = _a('以太坊上海升级临近', content: 'ETH 将升级，以太坊社区热议。ETH ETH。');
    final refs = resolver.resolve(a);
    final eth = refs.where((r) => r.symbol == 'ETH').single;
    expect(eth.inTitle, isTrue);
    expect(eth.mentions, greaterThanOrEqualTo(3));
  });

  test('同时命中多个标的，按 inTitle 优先、mentions 次之排序', () {
    final a = _a('BTC 与 eth', content: '比特币 bitcoin 狗狗币 doge');
    final refs = resolver.resolve(a);
    // BTC 与 ETH 都在标题中，mentions 多者靠前
    expect(refs.first.inTitle, isTrue);
    final syms = refs.map((r) => r.symbol).toSet();
    expect(syms.containsAll(['BTC', 'ETH', 'DOGE']), isTrue);
  });

  test('无任何标的出现时返回空列表', () {
    final a = _a('某地天气晴朗', content: '今天适合散步');
    expect(resolver.resolve(a), isEmpty);
  });

  test('「苹果」非财经语境不应误判（P0 词典无美股，天然不命中）', () {
    final a = _a('苹果好吃', content: '今天吃了两个苹果');
    expect(resolver.resolve(a), isEmpty);
  });

  test('同 symbol 多别名命中合并 mentions', () {
    final a = _a('ETH', content: '以太坊 以太 eth');
    final refs = resolver.resolve(a);
    final eth = refs.where((r) => r.symbol == 'ETH').single;
    expect(eth.mentions, greaterThanOrEqualTo(3));
  });
}
