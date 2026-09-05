import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/data/ticker_dictionary.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  test('词典包含四大链主流加密与生态标的', () {
    final dict = TickerDictionary();
    final syms = dict.entries.map((e) => e.symbol).toSet();
    expect(
      syms.containsAll(['BTC', 'ETH', 'SOL', 'BNB', 'AERO', 'HOOD']),
      isTrue,
    );
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

  test('SOL 别名包含「solana」', () {
    final dict = TickerDictionary();
    final sol = dict.entries.firstWhere((e) => e.symbol == 'SOL');
    expect(sol.aliases.contains('solana'), isTrue);
  });

  test('asset 类别正确', () {
    final dict = TickerDictionary();
    final bySym = {for (final e in dict.entries) e.symbol: e.asset};
    expect(bySym['BTC'], AssetClass.crypto);
    expect(bySym['SOL'], AssetClass.crypto);
    expect(bySym['BNB'], AssetClass.crypto);
  });
}
