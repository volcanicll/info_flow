import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_quote.dart';
import 'package:info_flow/features/signal_hub/presentation/widgets/ticker_chip.dart';
import 'package:info_flow/features/signal_hub/presentation/widgets/ticker_badge.dart';

void main() {
  final ref = TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 1, inTitle: true);

  testWidgets('TickerChip 渲染符号', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TickerChip(ref: ref)),
    ));
    expect(find.text('#ETH'), findsOneWidget);
  });

  testWidgets('TickerBadge 无 quote 时显示占位「--」', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TickerBadge(ref: ref, quote: null)),
    ));
    expect(find.text('ETH'), findsOneWidget);
    expect(find.textContaining('--'), findsWidgets);
  });

  testWidgets('TickerBadge 有 quote 时显示涨跌幅', (tester) async {
    final q = TickerQuote(
      symbol: 'ETH',
      asset: AssetClass.crypto,
      price: 1847.2,
      changePercent: 2.1,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TickerBadge(ref: ref, quote: q)),
    ));
    expect(find.textContaining('2.10%'), findsOneWidget);
    expect(find.textContaining('1,847.20'), findsWidgets);
  });
}
