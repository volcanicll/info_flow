import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/data/ticker_dictionary.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  test('词典包含主流加密与贵金属标的', () {
    final dict = TickerDictionary();
    final syms = dict.entries.map((e) => e.symbol).toSet();
    expect(syms.containsAll(['BTC', 'ETH', 'XAU', 'XAG']), isTrue);
  });

  test('每个 entry 的别名均为小写且非空', () {
    final dict = TickerDictionary();
    for (final e in dict.entries) {
      expect(e.aliases, isNotEmpty);
      for (final a in e.aliases) {
        expect(a.toLowerCase(), a);
        expect(a.trim(), a);
      }
    }
  });

  test('ETH 别名包含中文「以太坊」', () {
    final dict = TickerDictionary();
    final eth = dict.entries.firstWhere((e) => e.symbol == 'ETH');
    expect(eth.aliases.contains('以太坊'), isTrue);
  });

  test('asset 类别正确', () {
    final dict = TickerDictionary();
    final bySym = {for (final e in dict.entries) e.symbol: e.asset};
    expect(bySym['BTC'], AssetClass.crypto);
    expect(bySym['XAU'], AssetClass.metal);
  });
}
