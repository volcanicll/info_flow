# Signal Hub · P0 实现计划：脉搏时间线（加密 + 贵金属）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让「脉搏」成为首页（`/market`），把 RSS 资讯与加密/贵金属实时行情首次缝合：每篇文章识别出标的并展示实时行情徽章，资讯与异动交织成一条时间线。

**Architecture:** 新增 `features/signal_hub` feature 模块，内含 `TickerResolver`（本地词典 + Aho-Corasick 风格多模式匹配）与 `PulseTimeline` 入口。复用已有 `crypto_radar`（Binance）、`precious_metals`（新浪）作为行情源；通过扩展 `Article` 实体携带 `tickers` 字段，使现有 Feed/Reader 无侵入地展示徽章。P0 不实现 Signal Link 关联引擎（留待 P1），但预留接口与数据通道。

**Tech Stack:** Flutter 3.12+ / Dart 3.12+ / Riverpod（注解 + 代码生成）/ dio / flutter_test。不引入任何新依赖。

## Global Constraints

- **不新增 pub 依赖**：所有功能用已有包（`dio`/`html`/`riverpod`/`flutter`）实现。
- **代码生成后必须跑** `dart run build_runner build --delete-conflicting-outputs`：凡新增/修改 `@riverpod` 注解或 `part '*.g.dart'` 的任务，最后一步都要执行此命令并确认无报错。
- **遵循现有 lint**：`analysis_options.yaml` 已启用 `prefer_const_constructors` / `prefer_single_quotes` / `use_null_aware_elements` 等；所有新代码须通过 `flutter analyze`（`deprecated_member_use` 为 error 级）。
- **中文注释、英文命名**（遵循全局 CLAUDE.md）。
- **配色不破坏现有页面**：P0 不替换 `theme.dart` 已有的 `_up/_down/_brand` 令牌；信号中枢专用色作为新增 token 增量引入，仅供脉搏页与徽章使用。
- **每个 Task 独立可测、独立提交**；提交信息遵循 `<type>(<scope>): <description>`，不添加 Co-Authored-By。
- **标的词典覆盖范围**（P0）：仅加密（BTC/ETH/BNB/SOL/XRP/DOGE/ADA 等主流币 + 中文别名）+ 贵金属（黄金/白银）+ 宏观（美元指数/纳指，仅标签，行情在 P0 可空）。

## File Structure（新增/修改清单）

**新增 feature 模块 `lib/features/signal_hub/`**：
- `domain/entities/ticker_ref.dart` — `TickerRef` 值对象（symbol/asset/mentions/inTitle）
- `domain/entities/ticker_quote.dart` — `TickerQuote` 值对象（实时报价 + 涨跌幅）
- `data/ticker_dictionary.dart` — 标的词典（本地常量，含别名映射）
- `data/ticker_resolver.dart` — 标的识别引擎（多模式匹配 + 命中计数）
- `data/ticker_repository.dart` — 行情仓库（聚合 crypto + metals 两个源，返回 `Map<symbol, TickerQuote>`）
- `presentation/controllers/pulse_controller.dart` — 脉搏时间线状态（@riverpod）
- `presentation/pages/pulse_page.dart` — 脉搏首页 UI
- `presentation/widgets/ticker_badge.dart` — 标的徽章组件（行情 + 涨跌色）
- `presentation/widgets/ticker_chip.dart` — 轻量标的标签（Feed 页用，无行情）

**修改既有文件**：
- `lib/features/feed/domain/entities/article.dart` — 增加 `tickers` 字段 + `copyWith`/`toJson`/`fromJson` 兼容
- `lib/features/feed/presentation/widgets/article_card.dart` — Feed 卡片底部渲染 `TickerChip` 列表
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` — 替换为 `PulsePage`（或直接改路由指向 PulsePage）
- `lib/app/router.dart` — `/market` 路由 builder 改为 `PulsePage`
- `lib/shared/widgets/main_shell.dart` — 第一个 Tab 文案 `市场` → `脉搏`、图标改 `Icons.graphic_eq_rounded`

**测试**：
- `test/signal_hub/ticker_resolver_test.dart` — 识别引擎单测（核心，必须）
- `test/signal_hub/ticker_repository_test.dart` — 行情仓库聚合单测（用假 dio）
- `test/signal_hub/pulse_controller_test.dart` — 时间线装配单测

---

## Task 0: 扩展 Article 实体携带 tickers 字段

**Files:**
- Modify: `lib/features/feed/domain/entities/article.dart`
- Test: `test/feed/article_tickers_test.dart`

**Interfaces:**
- Produces: `Article` 新增字段 `List<TickerRef> tickers`（默认 `const []`）；`copyWith` 增加 `tickers` 参数；`toJson` 写入 `'tickers'`；`fromJson` 兼容缺失（旧数据回退为空列表）。
- Note: 此任务引入对 `TickerRef` 的依赖；为避免循环依赖，`TickerRef` 在本任务先行创建（见 Step 3），Task 1 再补全其能力。

- [ ] **Step 1: 写失败测试**

创建 `test/feed/article_tickers_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  test('Article 默认 tickers 为空列表', () {
    final a = _buildArticle();
    expect(a.tickers, isEmpty);
  });

  test('copyWith 携带 tickers', () {
    final a = _buildArticle();
    final ref = TickerRef(
      symbol: 'ETH',
      asset: AssetClass.crypto,
      mentions: 2,
      inTitle: true,
    );
    final b = a.copyWith(tickers: [ref]);
    expect(b.tickers.single.symbol, 'ETH');
  });

  test('toJson/fromJson 往返保持 tickers，旧数据缺失时回退空', () {
    final a = _buildArticle().copyWith(
      tickers: [
        TickerRef(symbol: 'BTC', asset: AssetClass.crypto, mentions: 1, inTitle: false),
      ],
    );
    final json = a.toJson();
    expect((json['tickers'] as List).length, 1);

    // 旧数据无 tickers 字段
    final legacy = Map<String, dynamic>.from(json)..remove('tickers');
    final b = Article.fromJson(legacy);
    expect(b.tickers, isEmpty);
  });
}

Article _buildArticle() => Article(
      id: 'a1',
      feedId: 'f1',
      feedName: '测试源',
      title: 'ETH 上海升级临近',
      url: 'https://example.com/a1',
    );
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/feed/article_tickers_test.dart`
Expected: FAIL — `TickerRef` / `AssetClass` 不存在，`tickers` 字段未定义。

- [ ] **Step 3: 先创建最小化 TickerRef（仅为本任务通过；Task 1 不再改动其结构）**

创建 `lib/features/signal_hub/domain/entities/ticker_ref.dart`：

```dart
/// 标的资产大类
enum AssetClass { crypto, metal, macro, usStock, cnStock }

/// 文章中识别出的某个金融标的的引用。
class TickerRef {
  final String symbol;   // 统一符号：'ETH' / 'XAU' / 'DXY'
  final AssetClass asset;
  final int mentions;    // 全文出现次数
  final bool inTitle;    // 是否出现在标题（权重更高）

  const TickerRef({
    required this.symbol,
    required this.asset,
    required this.mentions,
    required this.inTitle,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'asset': asset.name,
        'mentions': mentions,
        'inTitle': inTitle,
      };

  factory TickerRef.fromJson(Map<String, dynamic> json) => TickerRef(
        symbol: json['symbol'] as String,
        asset: AssetClass.values.byName(json['asset'] as String),
        mentions: json['mentions'] as int? ?? 1,
        inTitle: json['inTitle'] as bool? ?? false,
      );
}
```

- [ ] **Step 4: 给 Article 增加 tickers 字段**

在 `article.dart`：
- import `import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';`
- 字段区加 `final List<TickerRef> tickers;`
- 构造函数加 `this.tickers = const [],`
- `copyWith` 增加参数 `List<TickerRef>? tickers`，并在返回的 `Article(...)` 中传 `tickers: tickers ?? this.tickers,`（注意：现有 `copyWith` 没有透传 `tickers`，需补上）
- `toJson` 加 `'tickers': tickers.map((t) => t.toJson()).toList(),`
- `fromJson` 加 `tickers: (json['tickers'] as List<dynamic>?)?.map((e) => TickerRef.fromJson(e as Map<String, dynamic>)).toList() ?? const [],`

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/feed/article_tickers_test.dart`
Expected: PASS（3 个测试全过）

- [ ] **Step 6: 全量分析 + 提交**

Run: `flutter analyze lib/features/feed/domain/entities/article.dart lib/features/signal_hub/domain/entities/ticker_ref.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/domain/entities/ticker_ref.dart \
        lib/features/feed/domain/entities/article.dart \
        test/feed/article_tickers_test.dart
git commit -m "feat(signal-hub): Article 携带 tickers 字段，新增 TickerRef 实体"
```

---

## Task 1: 标的词典（TickerDictionary）

**Files:**
- Create: `lib/features/signal_hub/data/ticker_dictionary.dart`
- Test: `test/signal_hub/ticker_dictionary_test.dart`

**Interfaces:**
- Produces: `TickerDictionary` 单例类，方法 `List<DictEntry> get entries`；`DictEntry { String symbol; AssetClass asset; List<String> aliases; }`。别名均小写、去标点，供 Resolver 匹配。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/ticker_dictionary_test.dart`：

```dart
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
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/ticker_dictionary_test.dart`
Expected: FAIL — `TickerDictionary` / `DictEntry` 未定义。

- [ ] **Step 3: 实现词典**

创建 `lib/features/signal_hub/data/ticker_dictionary.dart`：

```dart
import '../domain/entities/ticker_ref.dart';

/// 词典单条：一个标的 + 它的若干匹配别名（已小写、去标点）。
class DictEntry {
  final String symbol;
  final AssetClass asset;
  final List<String> aliases;
  const DictEntry(this.symbol, this.asset, this.aliases);
}

/// 本地标的词典（P0 覆盖主流加密 + 贵金属 + 少量宏观标签）。
/// 设计为可热更新，P1/P2 扩展美股/A股时只需补充条目。
class TickerDictionary {
  TickerDictionary._();
  static final TickerDictionary instance = TickerDictionary._();
  factory TickerDictionary() => instance;

  List<DictEntry> get entries => const [
        // 加密货币：符号 + 中文名 + 常见别名
        DictEntry('BTC', AssetClass.crypto, ['btc', '比特币', '大饼', 'btc币']),
        DictEntry('ETH', AssetClass.crypto, ['eth', '以太坊', '以太', '以太币']),
        DictEntry('BNB', AssetClass.crypto, ['bnb', '币安币']),
        DictEntry('SOL', AssetClass.crypto, ['sol', '索拉纳', 'solana']),
        DictEntry('XRP', AssetClass.crypto, ['xrp', '瑞波', '瑞波币', 'ripple']),
        DictEntry('DOGE', AssetClass.crypto, ['doge', '狗狗币', 'dogecoin']),
        DictEntry('ADA', AssetClass.crypto, ['ada', '艾达币', 'cardano']),
        DictEntry('AVAX', AssetClass.crypto, ['avax', '雪崩', 'avalanche']),
        DictEntry('LINK', AssetClass.crypto, ['link', '链link', 'chainlink']),
        DictEntry('MATIC', AssetClass.crypto, ['matic', '马蹄', 'polygon']),
        // 贵金属
        DictEntry('XAU', AssetClass.metal, ['xau', '黄金', '纽约金', '国际金']),
        DictEntry('XAG', AssetClass.metal, ['xag', '白银', '国际银']),
        // 宏观（P0 仅作标签，行情可空）
        DictEntry('DXY', AssetClass.macro, ['dxy', '美元指数']),
        DictEntry('NDX', AssetClass.macro, ['ndx', '纳指', '纳斯达克指数']),
      ];
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/ticker_dictionary_test.dart`
Expected: PASS（4 个测试全过）

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/data/ticker_dictionary.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/data/ticker_dictionary.dart \
        test/signal_hub/ticker_dictionary_test.dart
git commit -m "feat(signal-hub): 新增本地标的词典（加密+贵金属+宏观）"
```

---

## Task 2: 标的识别引擎 TickerResolver

**Files:**
- Create: `lib/features/signal_hub/data/ticker_resolver.dart`
- Test: `test/signal_hub/ticker_resolver_test.dart`

**Interfaces:**
- Consumes: `TickerDictionary`（Task 1）、`Article`（Task 0）
- Produces: `TickerResolver` 类，方法 `List<TickerRef> resolve(Article article)`；返回按 `(inTitle desc, mentions desc)` 排序的引用列表，去重（同 symbol 合并 mentions）。
- 命中规则：在标题和正文的小写化文本里，逐个别名做子串计数（`text.count(alias)`）；symbol 自身（小写）也作为别名参与匹配。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/ticker_resolver_test.dart`：

```dart
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
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/ticker_resolver_test.dart`
Expected: FAIL — `TickerResolver` 未定义。

- [ ] **Step 3: 实现 Resolver**

创建 `lib/features/signal_hub/data/ticker_resolver.dart`：

```dart
import '../../feed/domain/entities/article.dart';
import '../domain/entities/ticker_ref.dart';
import 'ticker_dictionary.dart';

/// 标的识别引擎：基于本地词典的多模式子串匹配。
///
/// P0 路线：规则匹配（标题 + 正文小写化后逐别名计数）。
/// P1 可在此处增加「规则空命中 + 财经语境 → 调 LLM 回退」分支，不影响外部接口。
class TickerResolver {
  final TickerDictionary _dict;
  TickerResolver([TickerDictionary? dict])
      : _dict = dict ?? TickerDictionary();

  /// 识别文章涉及的所有标的，按 inTitle 优先、mentions 次之降序排列。
  List<TickerRef> resolve(Article article) {
    final title = _normalize(article.title);
    final body = _normalize(article.content ?? '');
    if (title.isEmpty && body.isEmpty) return const [];

    // symbol -> 累计数据
    final mentions = <String, int>{};
    final inTitle = <String, bool>{};
    final assetOf = <String, AssetClass>{};

    for (final e in _dict.entries) {
      final candidates = <String>[
        e.symbol.toLowerCase(),
        ...e.aliases,
      ].toSet();
      var count = 0;
      var hitTitle = false;
      for (final alias in candidates) {
        count += _countOccur(title, alias);
        if (_countOccur(title, alias) > 0) hitTitle = true;
        count += _countOccur(body, alias);
      }
      if (count > 0) {
        mentions[e.symbol] = (mentions[e.symbol] ?? 0) + count;
        inTitle[e.symbol] = (inTitle[e.symbol] ?? false) || hitTitle;
        assetOf[e.symbol] = e.asset;
      }
    }

    final refs = <TickerRef>[];
    mentions.forEach((sym, c) {
      refs.add(TickerRef(
        symbol: sym,
        asset: assetOf[sym]!,
        mentions: c,
        inTitle: inTitle[sym] ?? false,
      ));
    });
    refs.sort((a, b) {
      if (a.inTitle != b.inTitle) return a.inTitle ? -1 : 1;
      return b.mentions.compareTo(a.mentions);
    });
    return refs;
  }

  String _normalize(String s) => s.toLowerCase().trim();

  int _countOccur(String haystack, String needle) {
    if (needle.isEmpty) return 0;
    var count = 0;
    var idx = 0;
    while ((idx = haystack.indexOf(needle, idx)) != -1) {
      count++;
      idx += needle.length;
    }
    return count;
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/ticker_resolver_test.dart`
Expected: PASS（5 个测试全过）

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/data/ticker_resolver.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/data/ticker_resolver.dart \
        test/signal_hub/ticker_resolver_test.dart
git commit -m "feat(signal-hub): 实现 TickerResolver 标的识别引擎"
```

---

## Task 3: TickerQuote 实体 + 行情仓库 TickerRepository

**Files:**
- Create: `lib/features/signal_hub/domain/entities/ticker_quote.dart`
- Create: `lib/features/signal_hub/data/ticker_repository.dart`
- Test: `test/signal_hub/ticker_repository_test.dart`

**Interfaces:**
- Consumes: 已有 `BinanceApi`（`lib/features/crypto_radar/data/datasources/binance_api.dart`，方法 `getKlines(symbol)` 返回 `List<List<dynamic>>?`，索引 [4]=close）、`MetalsRepository.fetchPrices()`（返回 `List<MetalPrice>`，`MetalPrice.code` 为 `'XAU'/'XAG'`）。
- Produces:
  - `TickerQuote { String symbol; AssetClass asset; double price; double changePercent; }`，`changePercent` 正负决定涨跌；`bool get isUp => changePercent >= 0`。
  - `TickerRepository.fetchQuotes(Set<String> symbols) → Future<Map<String, TickerQuote>>`，缺数据的 symbol 不出现在 map 中（调用方按缺省处理）。
  - Riverpod provider：`tickerRepositoryProvider`（@riverpod），以及便捷 `tickerQuotesProvider`（@riverpod，watch `articleCacheProvider` 收集所有 symbol，返回 `Future<Map<String,TickerQuote>>`）。注意 `articleCacheProvider` 来自 `lib/core/state/article_cache.dart`。

- [ ] **Step 1: 写失败测试（用假 dio 构造假 Binance/Metals）**

创建 `test/signal_hub/ticker_repository_test.dart`：

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/crypto_radar/data/datasources/binance_api.dart';
import 'package:info_flow/features/precious_metals/data/metals_repository.dart';
import 'package:info_flow/features/signal_hub/data/ticker_repository.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

// 一个永远返回空数据的假 Dio：行情仓库应在接口失败时优雅降级（不抛、返回部分结果）。
class _FakeDio extends Dio {
  _FakeDio() : super();
}

void main() {
  test('crypto symbol 命中时返回报价，price 来自 K 线收盘', () async {
    final repo = TickerRepository._forTest(
      crypto: _FakeBinanceReturnsNull(),
      metals: MetalsRepository(_FakeDio()),
    );
    final q = await repo.fetchQuotes({'BTC', 'ETH', 'XAU'});
    // 假源都返回 null/空，因此应为空 map（验证降级不抛）
    expect(q, isEmpty);
  });

  test('传入空集合返回空 map', () async {
    final repo = TickerRepository._forTest(
      crypto: _FakeBinanceReturnsNull(),
      metals: MetalsRepository(_FakeDio()),
    );
    expect(await repo.fetchQuotes({}), isEmpty);
  });

  test('symbol 大小写不敏感：btc 与 BTC 视作同一', () async {
    final repo = TickerRepository._forTest(
      crypto: _FakeBinanceReturnsNull(),
      metals: MetalsRepository(_FakeDio()),
    );
    // 不抛异常即可（无网络，结果为空）
    await repo.fetchQuotes({'btc', 'Btc'});
  });
}

class _FakeBinanceReturnsNull implements BinanceApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
```

> 说明：真实网络单测不可靠，本测试聚焦「降级路径不抛异常」。Task 4 的 widget 测试会进一步覆盖 UI 的空态。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/ticker_repository_test.dart`
Expected: FAIL — `TickerQuote` / `TickerRepository` 未定义。

- [ ] **Step 3: 创建 TickerQuote**

创建 `lib/features/signal_hub/domain/entities/ticker_quote.dart`：

```dart
import 'ticker_ref.dart';

/// 某标的的实时报价快照。
class TickerQuote {
  final String symbol;
  final AssetClass asset;
  final double price;
  final double changePercent;

  const TickerQuote({
    required this.symbol,
    required this.asset,
    required this.price,
    required this.changePercent,
  });

  bool get isUp => changePercent >= 0;
}
```

- [ ] **Step 4: 实现 TickerRepository**

创建 `lib/features/signal_hub/data/ticker_repository.dart`：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/article_cache.dart';
import '../../../features/crypto_radar/data/datasources/binance_api.dart';
import '../../../features/precious_metals/data/metals_repository.dart';
import '../domain/entities/ticker_quote.dart';
import '../domain/entities/ticker_ref.dart';

part 'ticker_repository.g.dart';

/// 行情仓库：聚合 crypto（Binance）与 metals（新浪）两个数据源，
/// 对外统一以 symbol（大写）为键返回 TickerQuote。
///
/// 设计原则：任一源失败不得影响其它源；缺数据的 symbol 静默丢弃。
class TickerRepository {
  TickerRepository(this._crypto, this._metals);

  final BinanceApi _crypto;
  final MetalsRepository _metals;

  /// 仅用于测试：允许注入假源。
  @visibleForTesting
  TickerRepository._forTest({
    required BinanceApi crypto,
    required MetalsRepository metals,
  })  : _crypto = crypto,
        _metals = metals;

  /// 获取给定 symbol 集合的报价。未命中的 symbol 不出现在结果中。
  Future<Map<String, TickerQuote>> fetchQuotes(Set<String> symbols) async {
    final result = <String, TickerQuote>{};
    if (symbols.isEmpty) return result;

    final upper = symbols.map((s) => s.toUpperCase()).toSet();
    final cryptoSyms = <String>[];
    final metalSyms = <String>{};
    for (final s in upper) {
      // 资产类只能从词典推断；此处简化：已知 metal symbol 集合
      if (const {'XAU', 'XAG'}.contains(s)) {
        metalSyms.add(s);
      } else {
        cryptoSyms.add('${s}USDT'); // Binance 永续合约命名
      }
    }

    // 加密：逐 symbol 取最近 K 线收盘 + 前一日收盘算涨跌
    try {
      for (final sym in cryptoSyms) {
        final klines = await _crypto.getKlines(sym, limit: 2);
        if (klines == null || klines.length < 2) continue;
        final close = _n(klines.last[4]);
        final prevClose = _n(klines.first[4]);
        if (close <= 0 || prevClose <= 0) continue;
        final coin = sym.replaceAll('USDT', '');
        result[coin] = TickerQuote(
          symbol: coin,
          asset: AssetClass.crypto,
          price: close,
          changePercent: (close - prevClose) / prevClose * 100,
        );
      }
    } catch (_) {
      // 降级：忽略加密源
    }

    // 贵金属：一次性拉全部，按 code 过滤
    try {
      final metals = await _metals.fetchPrices();
      for (final m in metals) {
        if (metalSyms.contains(m.code)) {
          result[m.code] = TickerQuote(
            symbol: m.code,
            asset: AssetClass.metal,
            price: m.price,
            changePercent: m.changePercent,
          );
        }
      }
    } catch (_) {
      // 降级：忽略金属源
    }

    return result;
  }

  double _n(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

@riverpod
TickerRepository tickerRepository(TickerRepositoryRef ref) {
  // 复用现有 crypto_radar / precious_metals 已注册的依赖；
  // 若二者尚未暴露 provider，则在此处直接 new（dio 共享）。
  // 注：P0 阶段直接读取 BinanceApi 与 MetalsRepository 的现有 provider。
  // 如未找到对应 provider，按下方 fallback 构造。
  final crypto = BinanceApi(_sharedDio(ref));
  final metals = MetalsRepository(_sharedDio(ref));
  return TickerRepository(crypto, metals);
}

@riverpod
Future<Map<String, TickerQuote>> tickerQuotes(TickerQuotesRef ref) {
  final cache = ref.watch(articleCacheProvider);
  final syms = <String>{};
  for (final a in cache.values) {
    for (final t in a.tickers) {
      syms.add(t.symbol);
    }
  }
  return ref.watch(tickerRepositoryProvider).fetchQuotes(syms);
}

Dio _sharedDio(TickerRepositoryRef ref) {
  // 项目中 dio 通常通过 core/network 暴露；若不存在则就地构造。
  // P0 保持简单：新建一个 Dio 实例（BinanceApi/MetalsRepository 自带 headers）。
  return Dio();
}
```

> 实现注记：若 `core/network` 已有共享 `dioProvider`，把 `_sharedDio` 替换为 `ref.watch(dioProvider)` 即可；执行时先 `grep -rn "dioProvider\|Dio(" lib/core` 确认，再决定是否复用。测试用例不依赖此分支。

- [ ] **Step 5: 跑代码生成 + 测试**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成 `ticker_repository.g.dart`，无报错。

Run: `flutter test test/signal_hub/ticker_repository_test.dart`
Expected: PASS（3 个测试全过）

- [ ] **Step 6: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/`
Expected: No issues.

```bash
git add lib/features/signal_hub/domain/entities/ticker_quote.dart \
        lib/features/signal_hub/data/ticker_repository.dart \
        lib/features/signal_hub/data/ticker_repository.g.dart \
        test/signal_hub/ticker_repository_test.dart
git commit -m "feat(signal-hub): 实现 TickerQuote 与 TickerRepository 行情聚合"
```

---

## Task 4: TickerChip + TickerBadge 组件

**Files:**
- Create: `lib/features/signal_hub/presentation/widgets/ticker_chip.dart`
- Create: `lib/features/signal_hub/presentation/widgets/ticker_badge.dart`
- Test: `test/signal_hub/ticker_badge_test.dart`

**Interfaces:**
- Consumes: `TickerRef`、`TickerQuote?`、`AppTheme.up(brightness)`/`AppTheme.down(brightness)`（已有静态方法返回涨/跌色）。
- Produces:
  - `TickerChip(TickerRef ref)` — 轻量标签（仅符号，无行情），用于 Feed 页文章卡。
  - `TickerBadge({required TickerRef ref, TickerQuote? quote})` — 含价格 + 涨跌幅的徽章，用于脉搏页与未来 Lens；`quote` 为 null 时显示「--」并保留符号。

- [ ] **Step 1: 写失败测试（widget test）**

创建 `test/signal_hub/ticker_badge_test.dart`：

```dart
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
    expect(find.text('ETH'), findsOneWidget);
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
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/ticker_badge_test.dart`
Expected: FAIL — 组件未定义。

- [ ] **Step 3: 实现 TickerChip**

创建 `lib/features/signal_hub/presentation/widgets/ticker_chip.dart`：

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/ticker_ref.dart';

/// 轻量标的标签：仅符号，无行情。用于 Feed 页文章卡，保持阅读流纯净。
class TickerChip extends StatelessWidget {
  final TickerRef ref;
  final VoidCallback? onTap;
  const TickerChip({super.key, required this.ref, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '#${ref.symbol}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 实现 TickerBadge**

创建 `lib/features/signal_hub/presentation/widgets/ticker_badge.dart`：

```dart
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/ticker_quote.dart';
import '../../domain/entities/ticker_ref.dart';

/// 含实时价格 + 涨跌幅的标的徽章。用于脉搏页与未来的 Ticker Lens。
/// quote 为 null 时显示占位「--」，颜色为中性。
class TickerBadge extends StatelessWidget {
  final TickerRef ref;
  final TickerQuote? quote;
  final VoidCallback? onTap;
  const TickerBadge({super.key, required this.ref, this.quote, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final hasQuote = quote != null;
    final color = !hasQuote
        ? (theme.textTheme.bodySmall?.color ?? Colors.grey)
        : (quote!.isUp ? AppTheme.up(brightness) : AppTheme.down(brightness));

    final priceText = hasQuote ? _formatPrice(quote!.price) : '--';
    final chgText = hasQuote
        ? "${quote!.isUp ? '+' : ''}${quote!.changePercent.toStringAsFixed(2)}%"
        : '--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ref.symbol,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
            const SizedBox(width: 6),
            Text(priceText,
                style: TextStyle(
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                )),
            const SizedBox(width: 4),
            Text(chgText,
                style: TextStyle(
                  fontSize: 10,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000) {
      // 千分位
      final s = p.toStringAsFixed(2);
      final parts = s.split('.');
      final left = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$left.${parts[1]}';
    }
    if (p >= 1) return p.toStringAsFixed(2);
    return p.toStringAsFixed(4);
  }
}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/signal_hub/ticker_badge_test.dart`
Expected: PASS（3 个测试全过）

- [ ] **Step 6: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/presentation/widgets/`
Expected: No issues.

```bash
git add lib/features/signal_hub/presentation/widgets/ticker_chip.dart \
        lib/features/signal_hub/presentation/widgets/ticker_badge.dart \
        test/signal_hub/ticker_badge_test.dart
git commit -m "feat(signal-hub): 新增 TickerChip 与 TickerBadge 组件"
```

---

## Task 5: Feed 文章卡渲染 TickerChip

**Files:**
- Modify: `lib/features/feed/presentation/widgets/article_card.dart`

**Interfaces:**
- Consumes: `Article.tickers`（Task 0）、`TickerChip`（Task 4）。
- 行为：当 `article.tickers` 非空时，在文章卡底部（`_AiChip` 同级或其下方一行）渲染最多 4 个 `TickerChip`；为空则不渲染任何东西（保持现有视觉）。
- 重要：Resolver 尚未在 Feed 数据流中注入 `tickers`（那是 Task 7 的事），本任务只让卡片**具备展示能力**——即便 tickers 恒为空，现有 Feed 也不应变化。

- [ ] **Step 1: 读现有 article_card.dart 结构**

打开 `lib/features/feed/presentation/widgets/article_card.dart`，定位主内容 `Column` 中 `_AiChip()` 的渲染位置——插入点是其同级、`Column.children` 列表的紧随其后（用于追加标的标签行）。该文件约 160 行，`_AiChip` 出现在主内容列尾部。

- [ ] **Step 2: 修改 article_card.dart**

在文件顶部 import：
```dart
import '../../../../features/signal_hub/presentation/widgets/ticker_chip.dart';
```

在 `_AiChip()` 之后（仍在外层 `Column` 的 children 中）追加：
```dart
if (article.tickers.isNotEmpty) ...[
  const SizedBox(height: 8),
  Wrap(
    spacing: 6,
    runSpacing: 4,
    children: article.tickers
        .take(4)
        .map((t) => TickerChip(ref: t))
        .toList(),
  ),
],
```

- [ ] **Step 3: 写一个 widget 测试验证渲染**

追加到既有 `test/feed/`（若不存在则创建）`test/feed/article_card_tickers_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/feed/presentation/widgets/article_card.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

// 注：ArticleCard 是 ConsumerWidget，需 ProviderScope 包裹。
void main() {
  testWidgets('article.tickers 非空时卡片显示 TickerChip', (tester) async {
    final a = Article(
      id: 'a1',
      feedId: 'f1',
      feedName: '测试源',
      title: '以太坊升级',
      url: 'https://example.com/a1',
      tickers: [
        TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 2, inTitle: true),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [ArticleCard(article: a)]),
      ),
    ));
    expect(find.text('#ETH'), findsOneWidget);
  });

  testWidgets('article.tickers 为空时不渲染 chip 区', (tester) async {
    final a = Article(
      id: 'a2',
      feedId: 'f1',
      feedName: '测试源',
      title: '天气晴朗',
      url: 'https://example.com/a2',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [ArticleCard(article: a)]),
      ),
    ));
    // 无 # 开头文本
    expect(find.textContaining('#'), findsNothing);
  });
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/feed/article_card_tickers_test.dart`
Expected: PASS（2 个测试）

- [ ] **Step 5: 全量分析与回归**

Run: `flutter analyze lib/features/feed/`
Run: `flutter test`
Expected: 全部通过，无 analyze 报错。

- [ ] **Step 6: 提交**

```bash
git add lib/features/feed/presentation/widgets/article_card.dart \
        test/feed/article_card_tickers_test.dart
git commit -m "feat(feed): 文章卡渲染标的 TickerChip 标签"
```

---

## Task 6: 脉搏控制器 PulseController

**Files:**
- Create: `lib/features/signal_hub/presentation/controllers/pulse_controller.dart`
- Test: `test/signal_hub/pulse_controller_test.dart`

**Interfaces:**
- Consumes: `articleCacheProvider`（`core/state/article_cache.dart`）、`TickerResolver`（Task 2）、`tickerQuotesProvider`（Task 3）。
- Produces: `PulseController`（@riverpod）产出 `PulseState`：
  ```dart
  class PulseState {
    final List<Article> articles;              // 按发布时间倒序
    final Map<String, TickerQuote> quotes;     // symbol -> 报价
    const PulseState({required this.articles, required this.quotes});
  }
  ```
  逻辑：watch `articleCacheProvider` 取所有文章 → 用 `TickerResolver` 给每篇算 tickers（若文章本身 tickers 已存在则跳过，避免重复计算）→ 按 `publishedAt` 倒序 → 与 `tickerQuotesProvider` 的异步结果合并。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/pulse_controller_test.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
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
```

> 注：完整 controller 单测需要 override `articleCacheProvider`/`tickerQuotesProvider`，较重；P0 阶段用轻量单测覆盖 `PulseState` 与 Resolver 的 list 入口，深度行为留给 Task 7 的 widget 测试。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/pulse_controller_test.dart`
Expected: FAIL — `PulseState`/`PulseController` 未定义。

- [ ] **Step 3: 先给 TickerResolver 加 resolveList 便利方法**

在 `ticker_resolver.dart` 的 `TickerResolver` 类内追加：
```dart
/// 批量识别：对一组文章分别 resolve，并返回带 tickers 的新 Article（不可变拷贝）。
/// 原 Article 的已有 tickers 保留（不重复计算）。
List<Article> resolveList(List<Article> articles) {
  return articles.map((a) {
    if (a.tickers.isNotEmpty) return a;
    final refs = resolve(a);
    if (refs.isEmpty) return a;
    return a.copyWith(tickers: refs);
  }).toList();
}
```
（顶部已有 `import '../../feed/domain/entities/article.dart';`，无需新增 import。）

- [ ] **Step 4: 实现 PulseController**

创建 `lib/features/signal_hub/presentation/controllers/pulse_controller.dart`：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/article_cache.dart';
import '../../data/ticker_repository.dart';
import '../../data/ticker_resolver.dart';
import '../../../feed/domain/entities/article.dart';

part 'pulse_controller.g.dart';

class PulseState {
  final List<Article> articles;
  final Map<String, dynamic> quotes; // symbol -> TickerQuote；用 dynamic 避免 await
  const PulseState({required this.articles, required this.quotes});

  static const empty = PulseState(articles: [], quotes: {});
}

@riverpod
class PulseController extends _$PulseController {
  @override
  PulseState build() {
    final cache = ref.watch(articleCacheProvider);
    final resolver = TickerResolver();
    final enriched = resolver.resolveList(cache.values.toList());

    enriched.sort((a, b) {
      final ta = a.publishedAt ?? DateTime(2000);
      final tb = b.publishedAt ?? DateTime(2000);
      return tb.compareTo(ta);
    });

    // quotes 异步：先返回 articles，quotes 在 AsyncValue 完成后通过监听刷新
    final quotesAsync = ref.watch(tickerQuotesProvider);
    final quotes = <String, dynamic>{};
    final q = quotesAsync.valueOrNull;
    if (q != null) quotes.addAll(q);

    return PulseState(articles: enriched, quotes: quotes);
  }
}
```

- [ ] **Step 5: 代码生成 + 测试**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成 `pulse_controller.g.dart`。

Run: `flutter test test/signal_hub/pulse_controller_test.dart`
Expected: PASS。

- [ ] **Step 6: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/`
Expected: No issues.

```bash
git add lib/features/signal_hub/data/ticker_resolver.dart \
        lib/features/signal_hub/presentation/controllers/pulse_controller.dart \
        lib/features/signal_hub/presentation/controllers/pulse_controller.g.dart \
        test/signal_hub/pulse_controller_test.dart
git commit -m "feat(signal-hub): 实现 PulseController 时间线状态装配"
```

---

## Task 7: 脉搏首页 PulsePage UI

**Files:**
- Create: `lib/features/signal_hub/presentation/pages/pulse_page.dart`
- Test: `test/signal_hub/pulse_page_test.dart`

**Interfaces:**
- Consumes: `PulseController`（Task 6）、`TickerBadge`（Task 4）、`ArticleCard`（Task 5，复用为子组件）。
- 顶部：`🔴 实时 脉搏 Pulse` 标题 + 刷新按钮（P0 不实现红点呼吸，预留 `bool hasStrongSignal` 参数位即可）。
- 列表：`ListView.builder` 渲染 `PulseState.articles`；每条用现有 `ArticleCard`（已带 TickerChip），并在其下方追加一行 `TickerBadge`（仅当 quotes 命中时）。
- 空态：文章为空时显示「下拉刷新或稍后查看」。

- [ ] **Step 1: 写 widget 测试（覆盖空态 + 渲染一条）**

创建 `test/signal_hub/pulse_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/state/article_cache.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/signal_hub/presentation/pages/pulse_page.dart';

class _EmptyCacheOverride extends Override {
  const _EmptyCacheOverride();
}

void main() {
  testWidgets('文章为空时显示空态文案', (tester) async {
    final container = ProviderContainer(overrides: [
      articleCacheProvider.overrideWith(() => _EmptyCache()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PulsePage())),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('稍后'), findsWidgets);
  });
}

class _EmptyCache extends ArticleCache {
  @override
  Map<String, Article> build() => const {};
}
```

> 注：`ArticleCache` 是 generated `_$ArticleCache`，override 写法以 `overrideWith(() => ...)` 形式；若编译报错，改为对 `feedControllerProvider` 三个 type override 返回空列表。执行时以实际编译结果为准调整。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/pulse_page_test.dart`
Expected: FAIL — `PulsePage` 未定义。

- [ ] **Step 3: 实现 PulsePage**

创建 `lib/features/signal_hub/presentation/pages/pulse_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/presentation/widgets/article_card.dart';
import '../../domain/entities/ticker_quote.dart';
import '../controllers/pulse_controller.dart';

class PulsePage extends ConsumerWidget {
  const PulsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pulseControllerProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(theme)),
        if (state.articles.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无资讯，下拉刷新或稍后再看'),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: state.articles.length,
            itemBuilder: (context, i) {
              final a = state.articles[i];
              return Column(
                children: [
                  ArticleCard(
                    article: a,
                    onTap: () {}, // Task 8 接路由跳转 Reader
                  ),
                  if (a.tickers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: a.tickers.map((t) {
                          final q = state.quotes[t.symbol];
                          return TickerBadge(
                            ref: t,
                            quote: q is TickerQuote ? q : null,
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text('脉搏 Pulse', style: theme.textTheme.headlineLarge),
          const Spacer(),
          Icon(Icons.graphic_eq_rounded,
              size: 20, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试 + 必要时调整 override**

Run: `flutter test test/signal_hub/pulse_page_test.dart`
Expected: PASS。若 override 编译失败，按 Step 1 注记切换到 `feedControllerProvider` override。

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/presentation/`
Expected: No issues.

```bash
git add lib/features/signal_hub/presentation/pages/pulse_page.dart \
        test/signal_hub/pulse_page_test.dart
git commit -m "feat(signal-hub): 实现脉搏首页 PulsePage UI"
```

---

## Task 8: 接线路由 + 底部 Tab 改名 + Feed 注入 tickers

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `lib/shared/widgets/main_shell.dart`
- Modify: `lib/features/feed/presentation/controllers/feed_controller.dart`

**目标**：
1. `/market` 路由的 builder 从 `DashboardPage()` 改为 `PulsePage()`（保留 Dashboard 文件不删，留给 P1/P2 复用迷你行情条）。
2. `MainShell._tabs[0]` 由 `('市场', Icons.dashboard_rounded)` 改为 `('脉搏', Icons.graphic_eq_rounded)`。
3. Feed 加载流程中，文章落盘前经 `TickerResolver` 注入 tickers（一次性，结果随 Article 进 cache）。

- [ ] **Step 1: 修改 router.dart**

将：
```dart
import 'package:info_flow/features/dashboard/presentation/pages/dashboard_page.dart';
...
builder: (context, state) => const DashboardPage(),
```
改为：
```dart
import 'package:info_flow/features/signal_hub/presentation/pages/pulse_page.dart';
...
builder: (context, state) => const PulsePage(),
```
（路径仍是 `/market`，不改 routes 名 `market`，避免破坏 deep link。）

- [ ] **Step 2: 修改 main_shell.dart**

将 `_tabs` 第一项：
```dart
_TabItem(Icons.dashboard_rounded, '市场'),
```
改为：
```dart
_TabItem(Icons.graphic_eq_rounded, '脉搏'),
```

- [ ] **Step 3: 在 feed_controller 注入 tickers**

在 `feed_controller.dart` 顶部 import：
```dart
import 'package:info_flow/features/signal_hub/data/ticker_resolver.dart';
```
在 `_loadArticles()` 内 `_all.sort(...)` 之前追加一行（对每篇文章注入 tickers）：
```dart
final resolver = TickerResolver();
_all = resolver.resolveList(_all);
```
（`resolveList` 已在 Task 6 Step 3 添加：已有 tickers 的文章会被跳过。）

- [ ] **Step 4: 跑全量测试 + 分析**

Run: `dart run build_runner build --delete-conflicting-outputs`（router 用 generated provider，确保 .g.dart 同步）
Run: `flutter analyze`
Run: `flutter test`
Expected: analyze 无 error；全部已有 + 新增测试通过。

- [ ] **Step 5: 手动冒烟（可选但推荐）**

Run: `flutter run -d <emulator>` → 打开 App → 首页应为「脉搏 Pulse」→ 文章卡底部出现标的标签（如 `#ETH`）→ 切到「信息流」Tab 同样可见标签。
（若无模拟器，跳过此步，依赖自动化测试。）

- [ ] **Step 6: 提交**

```bash
git add lib/app/router.dart lib/shared/widgets/main_shell.dart \
        lib/features/feed/presentation/controllers/feed_controller.dart
git commit -m "feat(signal-hub): /market 路由切换为脉搏页，Feed 注入 tickers，底部 Tab 改名「脉搏」"
```

---

## Task 9: P0 收尾 —— 全量回归 + 文档更新

**Files:**
- Modify: `README.md`（功能矩阵追加「脉搏」行）

- [ ] **Step 1: 全量测试**

Run: `flutter test`
Expected: 全绿。

- [ ] **Step 2: 全量分析**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 3: 更新 README**

在 `README.md` 的功能特性表格「信息流」行上方插入一行：

```markdown
| 📡 **脉搏（Pulse）** | 信息+市场异动交织的实时时间线，资讯自动识别标的并展示实时行情徽章（信号中枢 P0） |
```

并在「功能特性」段落下方加一句差异化说明：

```markdown
> 💡 **核心特色 · 信号中枢（Signal Hub）**：把资讯与市场异动首次缝合——每条新闻自动识别涉及的标的（加密/贵金属），并展示实时行情徽章。「信息即信号」，让每条资讯带着它的市场身份证。完整方案见 [设计文档](docs/superpowers/specs/2026-07-01-signal-hub-design.md)。
```

- [ ] **Step 4: 提交**

```bash
git add README.md
git commit -m "docs(signal-hub): README 标注脉搏特色与信号中枢说明"
```

- [ ] **Step 5: 总结确认**

确认以下都为真：
- ✅ 首页（`/market`）= PulsePage，标题「脉搏 Pulse」
- ✅ Feed 文章自动带 `tickers`，文章卡底部渲染 `#BTC` 类标签
- ✅ 脉搏页文章下方渲染 TickerBadge（有行情时显示价格+涨跌，无则占位）
- ✅ `flutter analyze` 无 error，`flutter test` 全绿
- ✅ 未新增任何 pub 依赖
- ✅ P1（Signal Link 关联引擎）的入口已在 TickerRepository/PulseController 处预留

---

## Self-Review 记录

执行前由实现者自查（计划作者已先行核查）：

1. **Spec 覆盖**：设计文档第 3.2.1（脉搏时间线）、3.2.2（增强文章卡-TickerChip 部分）、3.2.3 Lens、3.2.4 Reader 行情条——P0 范围只覆盖前两者的「基础形态」。Lens 与 Reader 行情条、关联强度条、Signal Link 引擎明确**留给 P1**，符合设计文档第 5 节分期。视觉语言（深空蓝/荧光青）在 P0 不动现有主题，仅徽章用 `AppTheme.up/down`，符合 Global Constraints。
2. **占位符**：无 TBD/TODO；每个步骤含可执行命令或可粘贴代码。
3. **类型一致性**：`TickerRef`/`AssetClass`/`TickerQuote`/`PulseState` 在跨任务引用处签名一致；`TickerResolver.resolveList` 在 Task 2 定义、Task 6 与 Task 8 调用，签名稳定。
4. **范围**：9 个任务，单一可交付（首页=脉搏 + Feed 带标签），可独立发布。
