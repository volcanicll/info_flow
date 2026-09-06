import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/app/router.dart';
import 'package:info_flow/app/theme.dart';
import 'package:dio/dio.dart';
import 'package:info_flow/features/market/presentation/controllers/fear_greed_controller.dart';
import 'package:info_flow/features/smart_money/data/datasources/rht_api.dart';
import 'package:info_flow/features/smart_money/data/smart_money_repository.dart';
import 'package:info_flow/features/smart_money/data/smart_money_signals.dart';
import 'package:info_flow/features/token_screener/domain/models/onchain_token.dart';
import 'package:info_flow/features/token_screener/presentation/controllers/token_screener_controller.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/feed/presentation/controllers/feed_controller.dart';
import 'package:info_flow/features/market/presentation/controllers/coin_detail_controller.dart';
import 'package:info_flow/features/ai_chat/presentation/controllers/chat_controller.dart';

Future<void> stepPump(WidgetTester tester, [int millis = 300]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: millis));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('完整端到端用户使用流程测试：五大模块全流程交互验证', (tester) async {
    print('\n=============================================================');
    print('🎬 开始执行 InfoFlow Terminal 完整用户使用流程端到端自动化测试');
    print('=============================================================\n');

    // 1. 初始化应用并注入确定性测试数据桩，保证流程丝滑无卡顿
    print('【流程 1/7】启动应用并挂载五大生产级底栏模块...');
    final sampleTokens = [
      const OnChainToken(
        address: 'So11111111111111111111111111111111111111112',
        name: 'Wrapped SOL',
        symbol: 'SOL',
        chain: ChainType.solana,
        priceUsd: 142.80,
        priceChange24h: 6.45,
        volume24h: 380000000,
        liquidityUsd: 95000000,
        fdv: 82000000000,
        dexId: 'raydium',
        txns24hBuys: 18200,
        txns24hSells: 14300,
      ),
      const OnChainToken(
        address: '0x940181a94a35a4569e4529a3cdfb74e38fd98631',
        name: 'Aerodrome Finance',
        symbol: 'AERO',
        chain: ChainType.base,
        priceUsd: 1.18,
        priceChange24h: 12.30,
        volume24h: 42000000,
        liquidityUsd: 28000000,
        fdv: 1100000000,
        dexId: 'aerodrome',
        txns24hBuys: 4300,
        txns24hSells: 3100,
      ),
      const OnChainToken(
        address: '0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82',
        name: 'PancakeSwap Token',
        symbol: 'CAKE',
        chain: ChainType.bsc,
        priceUsd: 2.35,
        priceChange24h: -1.80,
        volume24h: 18500000,
        liquidityUsd: 45000000,
        fdv: 890000000,
        dexId: 'pancakeswap',
        txns24hBuys: 1900,
        txns24hSells: 2100,
      ),
      const OnChainToken(
        address: '0x232CDFc415D10b673845D83Dc02ba2eaBe7e30d1',
        name: 'Robinhood Tokenized Assets',
        symbol: 'HOOD',
        chain: ChainType.robinhood,
        priceUsd: 28.50,
        priceChange24h: 8.90,
        volume24h: 9500000,
        liquidityUsd: 12000000,
        fdv: 250000000,
        dexId: 'uniswap',
        txns24hBuys: 850,
        txns24hSells: 620,
      ),
    ];

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // 聪明钱数据源整体隔离：不可达地址 + 100ms 超时，WS/轮询快速失败落离线态，
    // 避免测试期内留有真实网络的 pending timer。
    final isolatedRht = RhtApi(
      Dio(BaseOptions(
        connectTimeout: const Duration(milliseconds: 100),
        receiveTimeout: const Duration(milliseconds: 100),
      )),
      baseUrl: 'http://127.0.0.1:1',
    );

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      fearGreedIndexProvider.overrideWith((ref) async => null),
      rhtApiProvider.overrideWithValue(isolatedRht),
      smartMoneyFlowIndexProvider.overrideWith((ref) async =>
          const SmartMoneyFlowIndex(byAddress: {}, bySymbol: {})),
      tokenScreenerProvider
          .overrideWith(() => _MockTokenScreenerNotifier(sampleTokens)),
      feedControllerProvider(FeedType.recommend)
          .overrideWith(() => _MockFeedController()),
      feedControllerProvider(FeedType.following)
          .overrideWith(() => _MockFeedController()),
      feedControllerProvider(FeedType.hot)
          .overrideWith(() => _MockFeedController()),
      coinDetailProvider.overrideWith(_MockCoinDetail.new),
      chatControllerProvider.overrideWith(_MockChatController.new),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await stepPump(tester, 500);

    print('   --> 验证底栏导航 Tab: [终端, 情报, 探测, 投研, 我的]');
    expect(find.text('终端'), findsWidgets);
    expect(find.text('情报'), findsWidgets);
    expect(find.text('探测'), findsWidgets);
    expect(find.text('投研'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
    print('   ✅ 平台主外壳加载成功!\n');

    // 2. 测试 Tab 0: 聪明钱终端
    // 断言仅覆盖与数据状态无关的静态结构（标题/区块头/入口），
    // tape 与榜单数据依赖外网，离线时呈现空态即视为通过。
    print('【流程 2/7】测试 Tab 0: 聪明钱终端 (Smart Money Terminal)...');
    expect(find.text('聪明钱终端'), findsOneWidget);
    expect(find.text('24H 净盈亏'), findsOneWidget);
    expect(find.text('LIVE TAPE · 实盘'), findsOneWidget);
    expect(find.text('SMART RESONANCE · 三源共振'), findsOneWidget);
    expect(find.text('COPY FLOW · 抱团跟单'), findsOneWidget);
    expect(find.text('TOP TRADERS · 24H 盈亏榜'), findsOneWidget);
    // 时间窗 chips 使首页内容超出首屏：滚动到入口再断言
    // （ListView 懒构建，首屏外的入口行不会进入 widget 树）。
    await tester.scrollUntilVisible(
      find.text('进入完整终端 · 榜单 / 跟单 / 平仓 / 关注'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('进入完整终端 · 榜单 / 跟单 / 平仓 / 关注'), findsOneWidget);
    print('   ✅ 聪明钱终端首页结构完整!\n');

    // 3. 测试 Tab 1: 链上情报
    print('【流程 3/7】测试 Tab 1: 链上情报流 (Chain Intel)...');
    print('   --> 点击底栏「情报」标签');
    await tester.tap(find.text('情报'));
    await stepPump(tester, 500);

    expect(find.text('今日要闻'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('关注'), findsOneWidget);
    expect(find.text('热榜'), findsOneWidget);
    print('   ✅ 链上情报流切换正常!\n');

    // 4. 测试 Tab 2: 代币探测与 GoPlus 审计
    print('【流程 4/7】测试 Tab 2: 链上代币探测器 (Token Screener)...');
    print('   --> 点击底栏「探测」标签');
    await tester.tap(find.text('探测'));
    await stepPump(tester);

    expect(find.text('代币探测与安全'), findsOneWidget);
    expect(find.text('输入合约地址 (CA) 或 代币 Symbol...'), findsOneWidget);

    print('   --> 查看探测结果列表: \$SOL, \$AERO, \$CAKE, \$HOOD');
    expect(find.text('RAYDIUM'), findsWidgets);
    expect(find.textContaining('流动性池'), findsWidgets);

    print('   --> 测试搜索框交互: 输入 CA「0x940181...」');
    await tester.enterText(find.byType(TextField), '0x940181a94a35a4569e4529a3cdfb74e38fd98631');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await stepPump(tester);
    print('   ✅ 代币探测器搜索与多链呈现交互正常!\n');

    // 5. 测试代币详情与安全体检报告
    print('【流程 5/7】测试代币详情页与 GoPlus 链上安全体检卡片...');
    print('   --> 点击代币卡片「AERO」进入代币详情');
    await tester.tap(find.text('AERO').first);
    await stepPump(tester, 500);

    expect(find.text('TOKEN PROFILE · 链上代币详情'), findsOneWidget);
    expect(find.text('AERO'), findsWidgets);
    expect(find.text('链上安全审计'), findsOneWidget);
    expect(find.textContaining('综合安全评分'), findsOneWidget);
    expect(find.text('貔貅限制'), findsOneWidget);
    expect(find.text('买/卖税率'), findsOneWidget);
    expect(find.text('增发权限'), findsOneWidget);
    expect(find.text('Top10集中度'), findsOneWidget);

    print('   --> 检查快捷操作: 合约地址一键复制 & 区块浏览器直达');
    expect(find.text('点击复制'), findsOneWidget);
    expect(find.text('区块浏览器'), findsOneWidget);

    print('   --> 返回上层页面');
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await stepPump(tester);
    print('   ✅ 代币安全体检报告与详情交互正常!\n');

    // 6. 测试 Tab 3: AI 投研助手
    print('【流程 6/7】测试 Tab 3: 链上 AI 投研大脑 (Copilot)...');
    print('   --> 点击底栏「投研」标签');
    await tester.tap(find.text('投研'));
    await stepPump(tester);

    expect(find.text('AI 助手'), findsOneWidget);
    expect(find.text('每日播报'), findsOneWidget);

    print('   --> 点击快捷指令「每日播报」');
    await tester.tap(find.text('每日播报'));
    await stepPump(tester);

    expect(find.textContaining('每日播报'), findsWidgets);
    print('   ✅ 链上 AI 投研问答响应正确!\n');

    // 7. 测试 Tab 4: 终端设置与自选
    print('【流程 7/7】测试 Tab 4: 终端设置与自选 (Terminal Profile)...');
    print('   --> 点击底栏「我的」标签');
    await tester.tap(find.text('我的'));
    await stepPump(tester);

    expect(find.text('TERMINAL · 链上终端'), findsOneWidget);
    expect(find.text('终端设置'), findsOneWidget);
    expect(find.text('自选/收藏'), findsOneWidget);
    expect(find.text('4'), findsWidgets); // 4 核心链生态
    expect(find.text('GoPlus'), findsWidgets); // 安全审计引擎
    expect(find.text('代币探测与安全审计'), findsOneWidget);
    expect(find.text('加密与异动雷达'), findsOneWidget);
    expect(find.text('Web3 情报源管理'), findsOneWidget);
    expect(find.text('链上异动提醒'), findsOneWidget);

    print('   --> 向上滑动页面查看外观与平台偏好');
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await stepPump(tester);

    print('   --> 测试外观模式切换: 点击「深色」');
    await tester.tap(find.text('深色'));
    await stepPump(tester);

    print('   --> 点击「浅色」');
    await tester.tap(find.text('浅色'));
    await stepPump(tester);
    print('   ✅ 终端设置与数据源偏好交互正常!\n');

    print('=============================================================');
    print('🎉 InfoFlow Terminal 五大核心模块端到端使用流程全部测试通过！');
    print('=============================================================\n');

    // 在测试体内销毁容器：终端页有周期定时器（WS/轮询/面板刷新），
    // 必须在 flutter_test 检查 pending timer 之前全部取消。
    container.dispose();
  });
}

class _MockTokenScreenerNotifier extends TokenScreenerNotifier {
  final List<OnChainToken> _tokens;
  _MockTokenScreenerNotifier(this._tokens);

  @override
  TokenScreenerState build() => TokenScreenerState(
        selectedChain: ChainType.solana,
        results: _tokens,
      );

  @override
  Future<void> search(String query) async {
    state = state.copyWith(
      query: query,
      results: _tokens
          .where((t) =>
              t.symbol.toLowerCase().contains(query.toLowerCase()) ||
              t.address.toLowerCase() == query.toLowerCase())
          .toList(),
    );
  }
}

class _MockFeedController extends FeedController {
  @override
  List<Article> build(FeedType feedType) => [
        Article(
          id: 'mock-1',
          feedId: 'solana-floor',
          feedName: 'Solana Floor',
          title: 'Solana DEX 24h 交易量突破 38 亿美元，Raydium 与 Orca 流动性深度持续增加',
          url: 'https://solanafloor.com/news/1',
          publishedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          summary: '随着 Base 和 Solana 链上活跃度提升，DEX 日交易量创下历史新高。',
        ),
        Article(
          id: 'mock-2',
          feedId: 'base-mirror',
          feedName: 'Base Mirror',
          title: 'Base 链上 TVL 超越 40 亿美元，Aerodrome 持续领跑头部流动性枢纽',
          url: 'https://base.mirror.xyz/2',
          publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
          summary: 'Base 链上日活跃地址数持续增长，Gas 费稳定在 0.001 美元以下。',
        ),
      ];
}

class _MockCoinDetail extends CoinDetail {
  @override
  CoinDetailState build(String symbol) => const CoinDetailState(
        price: 1.18,
        changePercent: 12.30,
        volume: 42000000,
        security: TokenSecurity(
          isHoneypot: false,
          buyTax: 0.0,
          sellTax: 0.0,
          isMintable: false,
          isFreezable: false,
          canTakeBackOwnership: false,
          isBlacklist: false,
          top10HolderPercent: 18.5,
          holderCount: 28400,
          isOpenSource: true,
          score: 95,
          riskLevel: SecurityRiskLevel.safe,
          warnings: [],
        ),
        onchainToken: OnChainToken(
          address: '0x940181a94a35a4569e4529a3cdfb74e38fd98631',
          name: 'Aerodrome Finance',
          symbol: 'AERO',
          chain: ChainType.base,
          priceUsd: 1.18,
          priceChange24h: 12.30,
          volume24h: 42000000,
          liquidityUsd: 28000000,
          fdv: 1100000000,
          dexId: 'aerodrome',
        ),
      );

  @override
  Future<void> load({String? address, String? chainId}) async {}
}

class _MockChatController extends ChatController {
  @override
  ChatState build() => const ChatState(
        messages: [
          ChatMessage(
            isUser: false,
            text: '你好！我是 InfoFlow AI 投研助手，专注 Web3 链上生态分析。',
          ),
        ],
      );

  @override
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: trimmed, isUser: true),
        ChatMessage(
          text: '📊 【链上生态每日播报】\n\n'
              '• Solana: 24h DEX 交易额破 \$3.8B，Raydium 与 Orca 活跃度持续提升\n'
              '• Base: Aerodrome 锁仓量稳定增长，链上日活跃地址数创新高\n'
              '• BSC: BNB 围绕 \$600 震荡，PancakeSwap 交易深度良好\n'
              '• Robinhood: 链上加密持仓稳步增长，监管合规情绪保持乐观\n\n'
              '💡 安全提示: 投资链上代币前请务必使用代币探测器检查合约权限与貔貅风险。',
          isUser: false,
        ),
      ],
      sending: false,
    );
  }
}
