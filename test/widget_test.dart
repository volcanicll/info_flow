import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:info_flow/app/theme.dart';

import 'package:info_flow/features/precious_metals/domain/models/metal_price.dart';
import 'package:info_flow/features/ai_models/domain/models/ai_model_item.dart';
import 'package:info_flow/features/crypto_radar/data/models/trade_signal.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';

void main() {
  // AppTheme 通过 google_fonts 构建 TextTheme，需已初始化绑定才能加载字体资源；
  // 关闭运行时联网拉取，测试环境走本地回退字体，避免异步网络错误。
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Model tests', () {
    test('MetalPrice correctly formats price', () {
      final price = const MetalPrice(
        name: '纽约金',
        code: 'XAU',
        currency: 'USD',
        price: 2345.67,
        changePercent: 1.23,
      );
      expect(price.isUp, true);
      expect(price.priceFormatted, '2345.67');
      expect(price.changeFormatted, '+1.23%');
    });

    test('MetalPrice shows negative change', () {
      final price = const MetalPrice(
        name: '纽约银',
        code: 'XAG',
        currency: 'USD',
        price: 24.567,
        changePercent: -0.45,
      );
      expect(price.isUp, false);
      expect(price.changeFormatted, '-0.45%');
    });

    test('AiModelItem formats downloads', () {
      final model = const AiModelItem(
        id: 'mistralai/Mistral-7B',
        name: 'Mistral-7B',
        description: 'A powerful model',
        downloads: 1500000,
        likes: 500,
        url: 'https://huggingface.co/mistralai/Mistral-7B',
      );
      expect(model.downloadsFormatted, '1.5M');
    });

    test('AiModelItem small downloads', () {
      final model = const AiModelItem(
        id: 'test/model',
        name: 'Test Model',
        description: '',
        downloads: 500,
        likes: 10,
        url: 'https://huggingface.co/test/model',
      );
      expect(model.downloadsFormatted, '500');
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
    // 用 testWidgets 承载：AppTheme 通过 google_fonts 构建 TextTheme，
    // 字体加载为 fire-and-forget 异步，需在 binding 的测试 zone 中容错。
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
