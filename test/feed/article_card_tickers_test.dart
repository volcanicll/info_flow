import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/app/theme.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/feed/presentation/widgets/article_card.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 注：ArticleCard 委托 ArticleRow（ConsumerWidget，watch libraryStore），
// 需 ProviderScope 覆盖 sharedPreferencesProvider。
void main() {
  testWidgets('article.tickers 非空时卡片显示 TickerChip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = const Article(
      id: 'a1',
      feedId: 'f1',
      feedName: '测试源',
      title: '以太坊升级',
      url: 'https://example.com/a1',
      tickers: [
        TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 2, inTitle: true),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ListView(children: [ArticleCard(article: a)]),
        ),
      ),
    ));
    expect(find.text('#ETH'), findsOneWidget);
  });

  testWidgets('article.tickers 为空时不渲染 chip 区', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = const Article(
      id: 'a2',
      feedId: 'f1',
      feedName: '测试源',
      title: '天气晴朗',
      url: 'https://example.com/a2',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ListView(children: [ArticleCard(article: a)]),
        ),
      ),
    ));
    // 无 # 开头文本
    expect(find.textContaining('#'), findsNothing);
  });
}
