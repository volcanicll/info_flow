import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:info_flow/app/theme.dart';
import 'package:info_flow/features/token_screener/domain/models/onchain_token.dart';
import 'package:info_flow/features/crypto_radar/data/models/trade_signal.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Model tests', () {
    test('OnChainToken correctly stores and parses values', () {
      const token = OnChainToken(
        address: 'So11111111111111111111111111111111111111112',
        name: 'Wrapped SOL',
        symbol: 'SOL',
        chain: ChainType.solana,
        priceUsd: 145.50,
        priceChange24h: 5.2,
        volume24h: 120000000,
        liquidityUsd: 50000000,
        fdv: 85000000000,
      );
      expect(token.symbol, 'SOL');
      expect(token.chain, ChainType.solana);
      expect(token.priceUsd, 145.50);
      expect(token.volume24h, 120000000);
    });

    test('TokenSecurity correctly handles safe defaults and evm checks', () {
      final safe = TokenSecurity.safeDefault();
      expect(safe.isHoneypot, false);
      expect(safe.score, 95);
      expect(safe.riskLevel, SecurityRiskLevel.safe);

      final honeypot = TokenSecurity.fromGoPlusEvm({
        'is_honeypot': '1',
        'buy_tax': '0.05',
        'sell_tax': '0.99',
      });
      expect(honeypot.isHoneypot, true);
      expect(honeypot.riskLevel, SecurityRiskLevel.danger);
      expect(honeypot.warnings.isNotEmpty, true);
    });

    test('TradeSignal stores correct values', () {
      final signal = const TradeSignal(
        coin: 'BTC',
        sym: 'BTCUSDT',
        direction: '做多',
        score: 75,
        strategy: '综合评分',
        price: 50000.0,
        entry: 50000.0,
        sl: 48000.0,
        tp: 55000.0,
        slPct: 4.0,
        margin: 100.0,
        notional: 1000.0,
        risk: 20.0,
        tags: ['OI异动', '低市值'],
        urgency: '⭐⭐',
      );
      expect(signal.coin, 'BTC');
      expect(signal.score, 75);
      expect(signal.tags.length, 2);
    });

    test('Article has correct default values', () {
      final article = const Article(
        id: 'test_1',
        feedId: 'test',
        feedName: 'Test Source',
        title: 'Test Article',
        url: 'https://example.com',
      );
      expect(article.isLiked, false);
      expect(article.isBookmarked, false);
      expect(article.isRead, false);
      expect(article.isReadLater, false);
    });
  });

  group('Theme tests', () {
    testWidgets('light theme is created correctly', (tester) async {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('dark theme is created correctly', (tester) async {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
    });
  });
}
