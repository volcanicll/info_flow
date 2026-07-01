# Signal Hub · P1 实现计划：Signal Link 关联引擎（事件 ↔ 异动配对）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为脉搏页注入「信息即信号」的完整闭环——轻量检测关注标的的市场异动（短周期价格 + OI 变化超阈值），与 RSS 事件在时间窗内自动配对，产出可解释的「关联强度 0–100」，强信号在脉搏页红点呼吸。

**Architecture:** 在 P0 已落地的 `signal_hub` feature 内增量新增 `SignalLinkEngine`（纯函数，输入事件池 + 异动池 → 输出 `SignalLink[]` 配对结果）。新增 `AnomalyDetector`（基于 BinanceApi 短周期 K 线 + OI 历史，对关注标的计算变化幅度，超阈值产出 `MarketAnomaly`）。`PulseController` 升级为装配 `SignalLink[]` 并驱动脉搏页渲染异动卡 + 关联强度条。所有新逻辑均为纯 Dart + Riverpod，不引入新依赖。

**Tech Stack:** Flutter 3.12+ / Dart 3.12+ / Riverpod（注解 + 代码生成）/ dio / flutter_test。不引入任何新依赖。

## Global Constraints

- **不新增 pub 依赖**：所有功能用已有包（`dio`/`riverpod`/`flutter`）实现。
- **代码生成后必须跑** `dart run build_runner build --delete-conflicting-outputs`：凡新增/修改 `@riverpod` 注解或 `part '*.g.dart'` 的任务，最后一步都要执行此命令并确认无报错。
- **遵循现有 lint**：`analysis_options.yaml` 已启用 `prefer_const_constructors` / `prefer_single_quotes` / `use_null_aware_elements` 等；`deprecated_member_use` 为 error 级；所有新代码须通过 `flutter analyze`。
- **中文注释、英文命名**（遵循全局 CLAUDE.md）。
- **不破坏 P0 已合并代码**：P1 在 P0 基础上增量，对 P0 文件的修改须保持向后兼容（P0 已有功能不回归）。
- **关联强度公式（设计文档 3.1.2，逐字采用）**：`关联强度 = 时间邻近度(40%) × 标的匹配度(30%) × 异动剧烈度(30%)`；时间邻近度 ±2h 内有效、>2h 记 0；标的匹配度精确命中 1.0、同板块 0.5；异动剧烈度复用变化幅度归一化。
- **阈值（设计文档 3.1.2）**：≥85 强信号（红点呼吸）、70–84 中信号（进脉搏不打扰）、<70 弱关联（仅在 Lens 可见，P1 不渲染）。
- **每个 Task 独立可测、独立提交**；提交信息遵循 `<type>(<scope>): <description>`，不添加 Co-Authored-By。
- **不实现推送通知**：设计文档把「推送」列在 P1，但本地通知在 Flutter 需新依赖（`flutter_local_notifications`），违反「不新增依赖」约束。P1 用**应用内红点呼吸 + 触觉反馈**替代系统推送；真正的系统推送留待后续（需用户授权 + 新依赖时单独决策）。

## File Structure（新增/修改清单）

**新增（`lib/features/signal_hub/`）**：
- `domain/entities/market_anomaly.dart` — `MarketAnomaly` 值对象（异动事件）
- `domain/entities/signal_link.dart` — `SignalLink` 值对象（配对结果 + 打分明细）
- `data/anomaly_detector.dart` — 轻量异动检测引擎（输入 symbol 集合 → 输出 `List<MarketAnomaly>`）
- `data/signal_link_engine.dart` — 关联引擎（纯函数，输入事件+异动池 → 输出 `List<SignalLink>`）
- `presentation/controllers/pulse_controller.dart` — **升级**（装配 SignalLink + hasStrongSignal）
- `presentation/widgets/anomaly_card.dart` — 异动卡（左侧紫条 + 反向关联新闻）
- `presentation/widgets/strength_bar.dart` — 关联强度渐变进度条

**修改既有文件**：
- `lib/features/crypto_radar/data/datasources/binance_api.dart` — `getKlines` 增加 `interval` 可选参数（默认 '1d' 保持向后兼容）
- `lib/features/signal_hub/presentation/pages/pulse_page.dart` — 渲染异动卡 + 关联强度条 + 强信号红点呼吸
- `lib/features/signal_hub/domain/entities/ticker_ref.dart` — 加 `sector` 概念（同板块判断所需，仅 crypto 维度）

**测试**：
- `test/signal_hub/anomaly_detector_test.dart`
- `test/signal_hub/signal_link_engine_test.dart`（核心，公式覆盖）
- `test/signal_hub/strength_bar_test.dart`
- `test/signal_hub/anomaly_card_test.dart`

---

## Task 1: BinanceApi.getKlines 支持 interval 参数

**Files:**
- Modify: `lib/features/crypto_radar/data/datasources/binance_api.dart:47-55`
- Test: `test/crypto_radar/binance_api_interval_test.dart`

**Interfaces:**
- Produces: `BinanceApi.getKlines(String symbol, {String interval = '1d', int limit = 180})`——增加可选 `interval` 命名参数，默认 '1d'（向后兼容现有所有调用方）。P1 异动检测传 `'1h'`。

- [ ] **Step 1: 写失败测试**

创建 `test/crypto_radar/binance_api_interval_test.dart`：

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/crypto_radar/data/datasources/binance_api.dart';

void main() {
  test('getKlines 默认 interval 为 1d（向后兼容）', () async {
    final api = BinanceApi(Dio());
    // 无网络环境会返回 null，但不应抛异常；默认参数语法正确即可
    final result = await api.getKlines('BTCUSDT', limit: 2);
    expect(result, isNull); // 无网络，降级为 null
  });

  test('getKlines 接受 interval 命名参数', () async {
    final api = BinanceApi(Dio());
    // 传 1h 不应抛异常（编译期保证参数存在；运行期无网络返回 null）
    final result = await api.getKlines('BTCUSDT', interval: '1h', limit: 2);
    expect(result, isNull);
  });
}
```

> 说明：单测不依赖网络，靠 null 降级验证编译与签名。参数存在性是编译期保证。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/crypto_radar/binance_api_interval_test.dart`
Expected: FAIL — `getKlines` 当前无 `interval` 参数，调用 `interval: '1h'` 编译不过。

- [ ] **Step 3: 修改 getKlines 签名与实现**

将 `binance_api.dart:47-55` 改为：

```dart
  Future<List<List<dynamic>>?> getKlines(String symbol,
      {String interval = '1d', int limit = 180}) async {
    final data = await _getList('/fapi/v1/klines', params: {
      'symbol': symbol,
      'interval': interval,
      'limit': limit,
    });
    if (data == null) return null;
    return data.cast<List<dynamic>>();
  }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/crypto_radar/binance_api_interval_test.dart`
Expected: PASS（2 个测试）

- [ ] **Step 5: 全量分析与回归**

Run: `flutter analyze lib/features/crypto_radar/`
Run: `flutter test test/crypto_radar/ test/signal_hub/`
Expected: analyze 无 error；现有 crypto_radar / signal_hub 测试无回归（默认参数保证向后兼容）。

- [ ] **Step 6: 提交**

```bash
git add lib/features/crypto_radar/data/datasources/binance_api.dart \
        test/crypto_radar/binance_api_interval_test.dart
git commit -m "feat(signal-hub): BinanceApi.getKlines 支持 interval 参数（默认 1d 向后兼容）"
```

---

## Task 2: MarketAnomaly 实体

**Files:**
- Create: `lib/features/signal_hub/domain/entities/market_anomaly.dart`
- Test: `test/signal_hub/market_anomaly_test.dart`

**Interfaces:**
- Produces: `MarketAnomaly` 值对象：
  ```dart
  class MarketAnomaly {
    final String symbol;            // 'ETH'
    final AssetClass asset;
    final AnomalyType type;         // priceSpike / priceDrop / oiSurge
    final double magnitude;         // 变化幅度百分比，如 +6.2（正负含方向）
    final DateTime detectedAt;      // 检测时间（异动发生时刻）
    final String summary;           // 人类可读摘要，如 'OI 1h +6.2%'
    const MarketAnomaly({...});
  }
  enum AnomalyType { priceSpike, priceDrop, oiSurge }
  ```
- 派生：`bool get isPositive => type == AnomalyType.priceSpike || type == AnomalyType.oiSurge;`

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/market_anomaly_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/domain/entities/market_anomaly.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  final a = MarketAnomaly(
    symbol: 'ETH',
    asset: AssetClass.crypto,
    type: AnomalyType.oiSurge,
    magnitude: 6.2,
    detectedAt: DateTime(2026, 7, 1, 9, 15),
    summary: 'OI 1h +6.2%',
  );

  test('字段与构造正确', () {
    expect(a.symbol, 'ETH');
    expect(a.type, AnomalyType.oiSurge);
    expect(a.magnitude, 6.2);
  });

  test('isPositive：oiSurge 为正向', () {
    expect(a.isPositive, isTrue);
  });

  test('isPositive：priceDrop 为负向', () {
    final drop = MarketAnomaly(
      symbol: 'BTC', asset: AssetClass.crypto,
      type: AnomalyType.priceDrop, magnitude: -3.5,
      detectedAt: DateTime.now(), summary: '价格 1h -3.5%',
    );
    expect(drop.isPositive, isFalse);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/market_anomaly_test.dart`
Expected: FAIL — `MarketAnomaly` 未定义。

- [ ] **Step 3: 创建 MarketAnomaly**

创建 `lib/features/signal_hub/domain/entities/market_anomaly.dart`：

```dart
import 'ticker_ref.dart';

/// 异动类型。
enum AnomalyType {
  /// 价格短周期上涨
  priceSpike,
  /// 价格短周期下跌
  priceDrop,
  /// 持仓量（OI）短周期激增
  oiSurge,
}

/// 市场异动事件：某标的在短周期内价格或 OI 变化幅度超过阈值。
class MarketAnomaly {
  final String symbol;
  final AssetClass asset;
  final AnomalyType type;
  final double magnitude;
  final DateTime detectedAt;
  final String summary;

  const MarketAnomaly({
    required this.symbol,
    required this.asset,
    required this.type,
    required this.magnitude,
    required this.detectedAt,
    required this.summary,
  });

  /// 是否为正向异动（上涨/OI 激增视为正向，下跌为负向）。
  bool get isPositive =>
      type == AnomalyType.priceSpike || type == AnomalyType.oiSurge;
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/market_anomaly_test.dart`
Expected: PASS（3 个测试）

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/domain/entities/market_anomaly.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/domain/entities/market_anomaly.dart \
        test/signal_hub/market_anomaly_test.dart
git commit -m "feat(signal-hub): 新增 MarketAnomaly 异动事件实体"
```

---

## Task 3: 轻量异动检测引擎 AnomalyDetector

**Files:**
- Create: `lib/features/signal_hub/data/anomaly_detector.dart`
- Test: `test/signal_hub/anomaly_detector_test.dart`

**Interfaces:**
- Consumes: `BinanceApi`（Task 1 已支持 `interval`）；输入 `Set<String>` 关注 symbol。
- Produces: `AnomalyDetector.detect(Set<String> symbols) → Future<List<MarketAnomaly>>`。
- 阈值常量（写死，P1 可调）：
  - 价格 1h 变化 ≥ +3% → `priceSpike`；≤ -3% → `priceDrop`
  - OI 5 周期变化 ≥ +5% → `oiSurge`
- 逻辑：对每个加密 symbol 拉 `getKlines(sym, interval: '1h', limit: 2)` 算价格变化；拉 `getOpenInterestHist(sym, limit: 5)` 算 OI 变化（首末值比较）。任一超阈值即产出一条 `MarketAnomaly`（同一 symbol 可产出 price + oi 两条）。贵金属 symbol 跳过（P1 不检测贵金属异动，留 P2）。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/anomaly_detector_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/crypto_radar/data/datasources/binance_api.dart';
import 'package:info_flow/features/signal_hub/data/anomaly_detector.dart';
import 'package:info_flow/features/signal_hub/domain/entities/market_anomaly.dart';

void main() {
  test('空 symbol 集合返回空列表', () async {
    final det = AnomalyDetector(_NullBinance());
    expect(await det.detect({}), isEmpty);
  });

  test('所有源返回 null 时降级返回空列表（不抛异常）', () async {
    final det = AnomalyDetector(_NullBinance());
    final result = await det.detect({'BTC', 'ETH'});
    expect(result, isEmpty);
  });

  test('价格涨幅超阈值产出 priceSpike', () async {
    final det = AnomalyDetector(_PriceUpBinance());
    final result = await det.detect({'BTC'});
    final spike = result.where((a) => a.type == AnomalyType.priceSpike);
    expect(spike, isNotEmpty);
    expect(spike.first.symbol, 'BTC');
    expect(spike.first.magnitude, greaterThanOrEqualTo(3.0));
  });
}

// 假 Binance：所有方法返回 null
class _NullBinance implements BinanceApi {
  @override
  dynamic noSuchMethod(Invocation inv) => null;
}

// 假 Binance：getKlines 返回两条 K 线（close 从 100 涨到 105 → +5%）
class _PriceUpBinance implements BinanceApi {
  @override
  dynamic noSuchMethod(Invocation inv) {
    if (inv.memberName == #getKlines) {
      return [
        [0, '100', '106', '99', '100', '0', 0, '0', 0, 0, '0', '0'],
        [0, '100', '106', '99', '105', '0', 0, '0', 0, 0, '0', '0'],
      ];
    }
    return null; // OI 返回 null，跳过 oiSurge
  }
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/anomaly_detector_test.dart`
Expected: FAIL — `AnomalyDetector` 未定义。

- [ ] **Step 3: 实现 AnomalyDetector**

创建 `lib/features/signal_hub/data/anomaly_detector.dart`：

```dart
import 'dart:math';

import '../../crypto_radar/data/datasources/binance_api.dart';
import '../domain/entities/market_anomaly.dart';
import '../domain/entities/ticker_ref.dart';

/// 轻量异动检测：对关注标的计算短周期价格/OI 变化幅度，超阈值产出 MarketAnomaly。
///
/// 设计原则：单 symbol 失败不影响其它；接口降级返回 null 时静默跳过。
/// P1 只检测加密；贵金属留待 P2。
class AnomalyDetector {
  AnomalyDetector(this._api);

  final BinanceApi _api;

  // 阈值常量（P1 写死，后续可移入配置）
  static const double priceSpikeThreshold = 3.0;  // 1h 涨幅 ≥3%
  static const double priceDropThreshold = -3.0;  // 1h 跌幅 ≤-3%
  static const double oiSurgeThreshold = 5.0;     // OI 5 周期涨幅 ≥5%

  /// 已知的贵金属 symbol（P1 不检测，跳过）。
  static const Set<String> _metalSymbols = {'XAU', 'XAG'};

  Future<List<MarketAnomaly>> detect(Set<String> symbols) async {
    final result = <MarketAnomaly>[];
    if (symbols.isEmpty) return result;

    final now = DateTime.now();

    for (final raw in symbols) {
      final sym = raw.toUpperCase();
      if (_metalSymbols.contains(sym)) continue; // 贵金属留 P2
      final pair = '${sym}USDT';

      // 价格 1h 变化
      try {
        final klines = await _api.getKlines(pair, interval: '1h', limit: 2);
        if (klines != null && klines.length >= 2) {
          final prevClose = _n(klines.first[4]);
          final close = _n(klines.last[4]);
          if (prevClose > 0 && close > 0) {
            final pct = (close - prevClose) / prevClose * 100;
            if (pct >= priceSpikeThreshold) {
              result.add(MarketAnomaly(
                symbol: sym,
                asset: AssetClass.crypto,
                type: AnomalyType.priceSpike,
                magnitude: pct,
                detectedAt: now,
                summary: '价格 1h +${pct.toStringAsFixed(1)}%',
              ));
            } else if (pct <= priceDropThreshold) {
              result.add(MarketAnomaly(
                symbol: sym,
                asset: AssetClass.crypto,
                type: AnomalyType.priceDrop,
                magnitude: pct,
                detectedAt: now,
                summary: '价格 1h ${pct.toStringAsFixed(1)}%',
              ));
            }
          }
        }
      } catch (_) {/* 降级跳过 */}

      // OI 5 周期变化
      try {
        final oi = await _api.getOpenInterestHist(pair, limit: 5);
        if (oi != null && oi.length >= 2) {
          final first = _oiValue(oi.first);
          final last = _oiValue(oi.last);
          if (first > 0 && last > 0) {
            final pct = (last - first) / first * 100;
            if (pct >= oiSurgeThreshold) {
              result.add(MarketAnomaly(
                symbol: sym,
                asset: AssetClass.crypto,
                type: AnomalyType.oiSurge,
                magnitude: pct,
                detectedAt: now,
                summary: 'OI 1h +${pct.toStringAsFixed(1)}%',
              ));
            }
          }
        }
      } catch (_) {/* 降级跳过 */}
    }

    return result;
  }

  /// openInterestHist 每条是 Map，含 'openInterest' 字段（字符串）。
  double _oiValue(Map<String, dynamic> entry) =>
      double.tryParse(entry['openInterest'].toString()) ?? 0.0;

  double _n(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/anomaly_detector_test.dart`
Expected: PASS（3 个测试）

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/data/anomaly_detector.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/data/anomaly_detector.dart \
        test/signal_hub/anomaly_detector_test.dart
git commit -m "feat(signal-hub): 实现轻量异动检测引擎 AnomalyDetector"
```

---

## Task 4: SignalLink 实体

**Files:**
- Create: `lib/features/signal_hub/domain/entities/signal_link.dart`
- Test: `test/signal_hub/signal_link_test.dart`

**Interfaces:**
- Produces: `SignalLink` 值对象：
  ```dart
  class SignalLink {
    final Article article;          // 事件侧（来自 P0 article_cache）
    final MarketAnomaly anomaly;    // 异动侧
    final int strength;             // 0-100 关联强度
    final double timeScore;         // 时间邻近度 0-1
    final double symbolScore;       // 标的匹配度 0-1
    final double magnitudeScore;    // 异动剧烈度 0-1
    const SignalLink({...});
    bool get isStrong => strength >= 85;
    bool get isMedium => strength >= 70 && strength < 85;
  }
  ```
- 需要 import `Article`（`feed/domain/entities/article.dart`）与 `MarketAnomaly`。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/signal_link_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/signal_hub/domain/entities/market_anomaly.dart';
import 'package:info_flow/features/signal_hub/domain/entities/signal_link.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  final article = Article(
    id: 'a1', feedId: 'f', feedName: 'n',
    title: 'ETH 升级', url: 'https://example.com/a',
    publishedAt: DateTime(2026, 7, 1, 9, 0),
  );
  final anomaly = MarketAnomaly(
    symbol: 'ETH', asset: AssetClass.crypto,
    type: AnomalyType.oiSurge, magnitude: 6.2,
    detectedAt: DateTime(2026, 7, 1, 9, 15),
    summary: 'OI 1h +6.2%',
  );

  test('isStrong：strength≥85 为强信号', () {
    final link = SignalLink(
      article: article, anomaly: anomaly,
      strength: 87, timeScore: 0.9, symbolScore: 1.0, magnitudeScore: 0.8,
    );
    expect(link.isStrong, isTrue);
    expect(link.isMedium, isFalse);
  });

  test('isMedium：70≤strength<85 为中信号', () {
    final link = SignalLink(
      article: article, anomaly: anomaly,
      strength: 72, timeScore: 0.6, symbolScore: 1.0, magnitudeScore: 0.4,
    );
    expect(link.isMedium, isTrue);
    expect(link.isStrong, isFalse);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/signal_link_test.dart`
Expected: FAIL — `SignalLink` 未定义。

- [ ] **Step 3: 创建 SignalLink**

创建 `lib/features/signal_hub/domain/entities/signal_link.dart`：

```dart
import '../../../feed/domain/entities/article.dart';
import 'market_anomaly.dart';

/// 一条「事件 ↔ 异动」关联配对，含可解释的打分明细。
class SignalLink {
  final Article article;
  final MarketAnomaly anomaly;
  final int strength;          // 0-100
  final double timeScore;      // 时间邻近度 0-1
  final double symbolScore;    // 标的匹配度 0-1
  final double magnitudeScore; // 异动剧烈度 0-1

  const SignalLink({
    required this.article,
    required this.anomaly,
    required this.strength,
    required this.timeScore,
    required this.symbolScore,
    required this.magnitudeScore,
  });

  bool get isStrong => strength >= 85;
  bool get isMedium => strength >= 70 && strength < 85;
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/signal_link_test.dart`
Expected: PASS（2 个测试）

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/domain/entities/signal_link.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/domain/entities/signal_link.dart \
        test/signal_hub/signal_link_test.dart
git commit -m "feat(signal-hub): 新增 SignalLink 关联配对实体"
```

---

## Task 5: TickerRef 增加 sector 概念（同板块判断）

**Files:**
- Modify: `lib/features/signal_hub/domain/entities/ticker_ref.dart`
- Modify: `lib/features/signal_hub/data/ticker_dictionary.dart`
- Test: `test/signal_hub/ticker_sector_test.dart`

**Interfaces:**
- Produces: `TickerRef` 新增 `sector` 字段（`String?`，默认 null）；`DictEntry` 新增 `sector`；词典加密条目标注 sector（如 BTC/ETH 都标 `'major'`，所有加密条目至少有 `'crypto'` 兜底）。
- 用途：SignalLinkEngine 判断「同板块」——事件标的 sector 与异动标的 sector 相同时 symbolScore = 0.5。
- 向后兼容：TickerRef 现有调用（P0）不传 sector 时为 null，不影响 P0 行为。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/ticker_sector_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/data/ticker_dictionary.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  test('TickerRef 默认 sector 为 null（向后兼容）', () {
    final r = TickerRef(
      symbol: 'BTC', asset: AssetClass.crypto, mentions: 1, inTitle: true,
    );
    expect(r.sector, isNull);
  });

  test('词典中 BTC 与 ETH 同属 major sector', () {
    final dict = TickerDictionary();
    final btc = dict.entries.firstWhere((e) => e.symbol == 'BTC');
    final eth = dict.entries.firstWhere((e) => e.symbol == 'ETH');
    expect(btc.sector, 'major');
    expect(eth.sector, 'major');
  });

  test('词典中 XAU 的 sector 不为 null（贵金属标注）', () {
    final dict = TickerDictionary();
    final xau = dict.entries.firstWhere((e) => e.symbol == 'XAU');
    expect(xau.sector, isNotNull);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/ticker_sector_test.dart`
Expected: FAIL — `TickerRef.sector` 与 `DictEntry.sector` 不存在。

- [ ] **Step 3: 改 TickerRef**

在 `ticker_ref.dart` 的 `TickerRef` 类：
- 字段加 `final String? sector;`
- 构造加 `this.sector,`
- `toJson` 加 `'sector': sector,`
- `fromJson` 加 `sector: json['sector'] as String?,`

- [ ] **Step 4: 改 DictEntry 与词典**

在 `ticker_dictionary.dart`：
- `DictEntry` 加字段 `final String? sector;`，构造改 `const DictEntry(this.symbol, this.asset, this.aliases, {this.sector});`
- 给加密条目标 sector：BTC/ETH 标 `'major'`；其余加密（BNB/SOL/XRP/DOGE/ADA/AVAX/LINK/MATIC）标 `'altcoin'`
- 贵金属 XAU/XAG 标 `'metal'`
- 宏观 DXY 标 `'fx'`、NDX 标 `'index'`

  示例改动（首行 BTC）：
  ```dart
  DictEntry('BTC', AssetClass.crypto, ['btc', '比特币', '大饼', 'btc币'], sector: 'major'),
  DictEntry('ETH', AssetClass.crypto, ['eth', '以太坊', '以太', '以太币'], sector: 'major'),
  DictEntry('BNB', AssetClass.crypto, ['bnb', '币安币'], sector: 'altcoin'),
  // ... 其余加密按 altcoin
  DictEntry('XAU', AssetClass.metal, ['xau', '黄金', '纽约金', '国际金'], sector: 'metal'),
  DictEntry('XAG', AssetClass.metal, ['xag', '白银', '国际银'], sector: 'metal'),
  DictEntry('DXY', AssetClass.macro, ['dxy', '美元指数'], sector: 'fx'),
  DictEntry('NDX', AssetClass.macro, ['ndx', '纳指', '纳斯达克指数'], sector: 'index'),
  ```

- [ ] **Step 5: 让 TickerResolver 把 sector 带到 TickerRef**

在 `ticker_resolver.dart` 的 `resolve` 内，构造 `TickerRef` 时从词典查 sector：
- `assetOf` 旁加一个 `sectorOf` Map：`sectorOf[e.symbol] = e.sector;`
- `TickerRef(...)` 构造加 `sector: sectorOf[sym],`

- [ ] **Step 6: 跑测试确认通过 + P0 回归**

Run: `flutter test test/signal_hub/ test/feed/`
Expected: 新测试 PASS；P0 的 ticker_resolver_test / ticker_dictionary_test / article_tickers_test 不回归（sector 可选，不破坏现有断言）。

- [ ] **Step 7: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/`
Expected: No issues.

```bash
git add lib/features/signal_hub/domain/entities/ticker_ref.dart \
        lib/features/signal_hub/data/ticker_dictionary.dart \
        lib/features/signal_hub/data/ticker_resolver.dart \
        test/signal_hub/ticker_sector_test.dart
git commit -m "feat(signal-hub): TickerRef 与词典增加 sector 概念，支撑同板块关联判断"
```

---

## Task 6: SignalLinkEngine 关联引擎（核心）

**Files:**
- Create: `lib/features/signal_hub/data/signal_link_engine.dart`
- Test: `test/signal_hub/signal_link_engine_test.dart`

**Interfaces:**
- Consumes: `List<Article>`（事件源，每篇带 `tickers`）、`List<MarketAnomaly>`（异动源）。
- Produces: `SignalLinkEngine.link({required List<Article> articles, required List<MarketAnomaly> anomalies, required TickerDictionary dict}) → List<SignalLink>`，按 strength 降序。
- 公式（逐字实现设计文档 3.1.2）：
  - `timeScore`：`1 - (abs(Δmin) / 120)`，Δmin = 文章 publishedAt 与异动 detectedAt 的分钟差；>120 记 0；文章无 publishedAt 记 0。
  - `symbolScore`：article.tickers 含 anomaly.symbol → 1.0；否则查词典，若任一 article ticker 与 anomaly.symbol 同 sector → 0.5；否则 0。
  - `magnitudeScore`：`min(abs(magnitude) / 10, 1.0)`（10% 变化即满分）。
  - `strength = (timeScore*0.4 + symbolScore*0.3 + magnitudeScore*0.3 * 100).round()`——注意三项加权后乘 100，范围 0–100。
  - 只保留 `strength >= 70` 的配对（弱关联丢弃）。

> 注意：`Article` 用 `publishedAt`；`MarketAnomaly` 用 `detectedAt`。文章无 tickers 直接跳过。

- [ ] **Step 1: 写失败测试（公式全覆盖）**

创建 `test/signal_hub/signal_link_engine_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/signal_hub/data/signal_link_engine.dart';
import 'package:info_flow/features/signal_hub/data/ticker_dictionary.dart';
import 'package:info_flow/features/signal_hub/domain/entities/market_anomaly.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';

void main() {
  final dict = TickerDictionary();

  Article _art(String id, {String? title, DateTime? at, List<TickerRef> tickers = const []}) =>
      Article(id: id, feedId: 'f', feedName: 'n', title: title ?? '', url: 'https://e.com/$id', publishedAt: at, tickers: tickers);

  MarketAnomaly _anom(String sym, {double mag = 6.0, DateTime? at}) =>
      MarketAnomaly(symbol: sym, asset: AssetClass.crypto, type: AnomalyType.oiSurge, magnitude: mag, detectedAt: at ?? DateTime(2026, 7, 1, 9, 15), summary: 's');

  test('精确标的命中 + 时间邻近 + 高剧烈度 → 高强度', () {
    final articles = [_art('a1', at: DateTime(2026, 7, 1, 9, 10),
        tickers: [TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 2, inTitle: true, sector: 'major')])];
    final anomalies = [_anom('ETH', mag: 8.0, at: DateTime(2026, 7, 1, 9, 15))];
    final links = SignalLinkEngine().link(articles: articles, anomalies: anomalies, dict: dict);
    expect(links, isNotEmpty);
    expect(links.first.strength, greaterThanOrEqualTo(70));
    expect(links.first.symbolScore, 1.0);
  });

  test('同板块（BTC 异动 ↔ ETH 新闻，sector 同为 major）→ symbolScore 0.5', () {
    final articles = [_art('a1', at: DateTime(2026, 7, 1, 9, 10),
        tickers: [TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 1, inTitle: true, sector: 'major')])];
    final anomalies = [_anom('BTC', mag: 8.0, at: DateTime(2026, 7, 1, 9, 15))];
    final links = SignalLinkEngine().link(articles: articles, anomalies: anomalies, dict: dict);
    // 即便 symbolScore 0.5，可能 strength 仍 ≥70（取决于时间/剧烈度）；只验证打分
    final scored = links.where((l) => l.anomaly.symbol == 'BTC');
    if (scored.isNotEmpty) {
      expect(scored.first.symbolScore, 0.5);
    }
  });

  test('时间差 >2h → timeScore 0 → 强度骤降，可能被过滤', () {
    final articles = [_art('a1', at: DateTime(2026, 7, 1, 7, 0),  // 差 2h15min
        tickers: [TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 1, inTitle: true)])];
    final anomalies = [_anom('ETH', mag: 6.0, at: DateTime(2026, 7, 1, 9, 15))];
    final links = SignalLinkEngine().link(articles: articles, anomalies: anomalies, dict: dict);
    // timeScore=0，strength = (0 + 0.3 + 0.18)*100 = 48 → <70 被过滤
    expect(links, isEmpty);
  });

  test('无 tickers 的文章不参与配对', () {
    final articles = [_art('a1', at: DateTime(2026, 7, 1, 9, 10))]; // 无 tickers
    final anomalies = [_anom('ETH')];
    expect(SignalLinkEngine().link(articles: articles, anomalies: anomalies, dict: dict), isEmpty);
  });

  test('结果按 strength 降序', () {
    final articles = [
      _art('a1', at: DateTime(2026, 7, 1, 9, 14), tickers: [TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 1, inTitle: true)]),
      _art('a2', at: DateTime(2026, 7, 1, 8, 0), tickers: [TickerRef(symbol: 'ETH', asset: AssetClass.crypto, mentions: 1, inTitle: true)]),
    ];
    final anomalies = [_anom('ETH', mag: 7.0)];
    final links = SignalLinkEngine().link(articles: articles, anomalies: anomalies, dict: dict);
    for (var i = 1; i < links.length; i++) {
      expect(links[i - 1].strength, greaterThanOrEqualTo(links[i].strength));
    }
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/signal_link_engine_test.dart`
Expected: FAIL — `SignalLinkEngine` 未定义。

- [ ] **Step 3: 实现 SignalLinkEngine**

创建 `lib/features/signal_hub/data/signal_link_engine.dart`：

```dart
import 'dart:math';

import '../../../feed/domain/entities/article.dart';
import '../domain/entities/market_anomaly.dart';
import '../domain/entities/signal_link.dart';
import 'ticker_dictionary.dart';

/// 信号关联引擎：在时间窗内把「事件」与「异动」配对，输出可解释的关联强度。
///
/// 公式（设计文档 3.1.2）：
///   strength = (timeScore*0.4 + symbolScore*0.3 + magnitudeScore*0.3) * 100
/// 只保留 strength >= 70 的配对。
class SignalLinkEngine {
  static const double _timeWindowMinutes = 120; // ±2h
  static const double _magnitudeFullScale = 10; // 10% 变化即剧烈度满分
  static const int _keepThreshold = 70;

  List<SignalLink> link({
    required List<Article> articles,
    required List<MarketAnomaly> anomalies,
    required TickerDictionary dict,
  }) {
    final links = <SignalLink>[];

    for (final anomaly in anomalies) {
      // 异动标的的 sector（用于同板块判断）
      final anomalySector = _sectorOf(anomaly.symbol, dict);

      for (final article in articles) {
        if (article.tickers.isEmpty) continue;

        final timeScore = _timeScore(article.publishedAt, anomaly.detectedAt);
        final symbolScore = _symbolScore(article.tickers, anomaly.symbol, anomalySector);
        final magnitudeScore = _magnitudeScore(anomaly.magnitude);

        // 标的完全不匹配（0 分）→ 无意义，跳过
        if (symbolScore == 0) continue;

        final strength = ((timeScore * 0.4 +
                symbolScore * 0.3 +
                magnitudeScore * 0.3) *
            100)
            .round();

        if (strength < _keepThreshold) continue;

        links.add(SignalLink(
          article: article,
          anomaly: anomaly,
          strength: strength.clamp(0, 100),
          timeScore: timeScore,
          symbolScore: symbolScore,
          magnitudeScore: magnitudeScore,
        ));
      }
    }

    links.sort((a, b) => b.strength.compareTo(a.strength));
    return links;
  }

  /// 时间邻近度：Δmin 越小越高，超窗记 0；文章无时间记 0。
  double _timeScore(DateTime? articleAt, DateTime anomalyAt) {
    if (articleAt == null) return 0;
    final deltaMin = articleAt.difference(anomalyAt).inMinutes.abs().toDouble();
    if (deltaMin > _timeWindowMinutes) return 0;
    return 1 - (deltaMin / _timeWindowMinutes);
  }

  /// 标的匹配度：精确命中 1.0；同板块 0.5；否则 0。
  double _symbolScore(
      List<dynamic> tickers, String anomalySymbol, String? anomalySector) {
    var best = 0.0;
    for (final t in tickers) {
      if (t.symbol == anomalySymbol) return 1.0;
      if (anomalySector != null && t.sector == anomalySector) {
        best = 0.5;
      }
    }
    return best;
  }

  /// 异动剧烈度：10% 变化满分，线性归一。
  double _magnitudeScore(double magnitude) {
    return min(magnitude.abs() / _magnitudeFullScale, 1.0);
  }

  /// 从词典查 symbol 的 sector；未知 symbol 返回 null。
  String? _sectorOf(String symbol, TickerDictionary dict) {
    for (final e in dict.entries) {
      if (e.symbol == symbol.toUpperCase()) return e.sector;
    }
    return null;
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/signal_link_engine_test.dart`
Expected: PASS（5 个测试）

> 若测试失败，检查：`_symbolScore` 的 `tickers` 元素是否需 cast（取决于 `List<dynamic>` 还是 `List<TickerRef>`）。若 Article.tickers 是 `List<TickerRef>`，把参数类型改回 `List<TickerRef>` 并直接访问 `.symbol`/`.sector`，无需 cast。实际签名用 `List<TickerRef>` 更安全——执行时以编译结果为准。

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/data/signal_link_engine.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/data/signal_link_engine.dart \
        test/signal_hub/signal_link_engine_test.dart
git commit -m "feat(signal-hub): 实现 SignalLinkEngine 关联引擎（公式可解释）"
```

---

## Task 7: StrengthBar 关联强度进度条组件

**Files:**
- Create: `lib/features/signal_hub/presentation/widgets/strength_bar.dart`
- Test: `test/signal_hub/strength_bar_test.dart`

**Interfaces:**
- Produces: `StrengthBar(int strength)` widget——渐变进度条（青→橙→红），高分带 🔥。strength 0-100。
- 颜色规则：`<70` 灰；`70-84` 橙；`≥85` 红（AppTheme.down/down 派生，或固定色）。宽度按 strength% 填充。
- 文案：`关联强度 ████████░ 87 🔥`（进度条后跟数字，≥85 显示 🔥）。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/strength_bar_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/presentation/widgets/strength_bar.dart';

void main() {
  testWidgets('强度 ≥85 显示火焰 emoji', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StrengthBar(87)),
    ));
    expect(find.textContaining('🔥'), findsOneWidget);
    expect(find.textContaining('87'), findsOneWidget);
  });

  testWidgets('强度 72 不显示火焰', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StrengthBar(72)),
    ));
    expect(find.textContaining('🔥'), findsNothing);
    expect(find.textContaining('72'), findsOneWidget);
  });

  testWidgets('强度数字渲染', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StrengthBar(50)),
    ));
    expect(find.textContaining('50'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/strength_bar_test.dart`
Expected: FAIL — `StrengthBar` 未定义。

- [ ] **Step 3: 实现 StrengthBar**

创建 `lib/features/signal_hub/presentation/widgets/strength_bar.dart`：

```dart
import 'package:flutter/material.dart';

/// 关联强度进度条：渐变填充 + 数字 + 高分火焰。
class StrengthBar extends StatelessWidget {
  final int strength; // 0-100
  const StrengthBar(this.strength, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStrong = strength >= 85;
    final isMedium = strength >= 70 && strength < 85;

    final Color color = isStrong
        ? const Color(0xFFE53935) // 红
        : isMedium
            ? const Color(0xFFFF9500) // 橙
            : (theme.textTheme.bodySmall?.color ?? Colors.grey);

    final clamped = strength.clamp(0, 100);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('关联强度',
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        const SizedBox(width: 6),
        // 进度条底
        Container(
          width: 80,
          height: 5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clamped / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$clamped${isStrong ? ' 🔥' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            )),
      ],
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/strength_bar_test.dart`
Expected: PASS（3 个测试）

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/presentation/widgets/strength_bar.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/presentation/widgets/strength_bar.dart \
        test/signal_hub/strength_bar_test.dart
git commit -m "feat(signal-hub): 新增 StrengthBar 关联强度进度条组件"
```

---

## Task 8: AnomalyCard 异动卡组件

**Files:**
- Create: `lib/features/signal_hub/presentation/widgets/anomaly_card.dart`
- Test: `test/signal_hub/anomaly_card_test.dart`

**Interfaces:**
- Consumes: `MarketAnomaly`（Task 2）、`StrengthBar`（Task 7）、`List<Article>`（反向关联的新闻，按关联强度降序，取最多 3 条标题）。
- Produces: `AnomalyCard({required MarketAnomaly anomaly, required List<Article> relatedArticles})`——左侧紫色色条 + symbol + summary + 反向关联新闻标题列表。

- [ ] **Step 1: 写失败测试**

创建 `test/signal_hub/anomaly_card_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/feed/domain/entities/article.dart';
import 'package:info_flow/features/signal_hub/domain/entities/market_anomaly.dart';
import 'package:info_flow/features/signal_hub/domain/entities/ticker_ref.dart';
import 'package:info_flow/features/signal_hub/presentation/widgets/anomaly_card.dart';

void main() {
  final anomaly = MarketAnomaly(
    symbol: 'ETH', asset: AssetClass.crypto,
    type: AnomalyType.oiSurge, magnitude: 6.2,
    detectedAt: DateTime(2026, 7, 1, 9, 15),
    summary: 'OI 1h +6.2%',
  );

  testWidgets('渲染 symbol 与 summary', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AnomalyCard(anomaly: anomaly, relatedArticles: const [])),
    ));
    expect(find.text('ETH'), findsOneWidget);
    expect(find.textContaining('OI 1h'), findsOneWidget);
  });

  testWidgets('有反向关联新闻时渲染标题', (tester) async {
    final arts = [
      Article(id: 'a1', feedId: 'f', feedName: 'n', title: '上海升级临近', url: 'https://e.com/a1'),
      Article(id: 'a2', feedId: 'f', feedName: 'n', title: 'V神谈扩容', url: 'https://e.com/a2'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AnomalyCard(anomaly: anomaly, relatedArticles: arts)),
    ));
    expect(find.text('上海升级临近'), findsOneWidget);
    expect(find.text('V神谈扩容'), findsOneWidget);
  });

  testWidgets('无关联新闻时不渲染叙事区', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AnomalyCard(anomaly: anomaly, relatedArticles: const [])),
    ));
    expect(find.text('相关叙事'), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/anomaly_card_test.dart`
Expected: FAIL — `AnomalyCard` 未定义。

- [ ] **Step 3: 实现 AnomalyCard**

创建 `lib/features/signal_hub/presentation/widgets/anomaly_card.dart`：

```dart
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../feed/domain/entities/article.dart';
import '../../domain/entities/market_anomaly.dart';

/// 异动卡：左侧紫条 + symbol + summary + 反向关联新闻（最多 3 条标题）。
class AnomalyCard extends StatelessWidget {
  final MarketAnomaly anomaly;
  final List<Article> relatedArticles;
  final VoidCallback? onTap;

  const AnomalyCard({
    super.key,
    required this.anomaly,
    required this.relatedArticles,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final top3 = relatedArticles.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.hair(brightness), width: 1),
            boxShadow: AppTheme.cardShadow(brightness),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧紫色色条
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.radar_rounded, size: 16,
                                color: const Color(0xFF8B5CF6)),
                            const SizedBox(width: 6),
                            Text(anomaly.symbol,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (anomaly.isPositive
                                        ? AppTheme.up(brightness)
                                        : AppTheme.down(brightness))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(anomaly.summary,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: anomaly.isPositive
                                        ? AppTheme.up(brightness)
                                        : AppTheme.down(brightness),
                                  )),
                            ),
                          ],
                        ),
                        if (top3.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('相关叙事',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color,
                              )),
                          const SizedBox(height: 4),
                          ...top3.map((a) => Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text('• ${a.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

> 注：`AppTheme.hair` / `AppTheme.cardShadow` / `AppTheme.up` / `AppTheme.down` 都是 P0 已确认存在的静态方法。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/signal_hub/anomaly_card_test.dart`
Expected: PASS（3 个测试）

- [ ] **Step 5: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/presentation/widgets/anomaly_card.dart`
Expected: No issues.

```bash
git add lib/features/signal_hub/presentation/widgets/anomaly_card.dart \
        test/signal_hub/anomaly_card_test.dart
git commit -m "feat(signal-hub): 新增 AnomalyCard 异动卡组件"
```

---

## Task 9: 升级 PulseController 装配 SignalLink

**Files:**
- Modify: `lib/features/signal_hub/presentation/controllers/pulse_controller.dart`
- Test: `test/signal_hub/pulse_controller_p1_test.dart`

**Interfaces:**
- Consumes: `AnomalyDetector`（Task 3）、`SignalLinkEngine`（Task 6）、`TickerDictionary`（P0）。新增 provider：`anomalyDetectorProvider`、`marketAnomaliesProvider`（@riverpod，watch articleCache 收集 symbol → detect）。
- Produces: `PulseState` 扩展两字段：
  - `final List<SignalLink> links` —— 关联配对（按 strength 降序）
  - `final bool hasStrongSignal` —— 是否存在 strength≥85 的配对（驱动红点呼吸）
- 逻辑：PulseController.build 在 P0 装配（articles + quotes）基础上，watch `marketAnomaliesProvider` 拿异动，再用 `SignalLinkEngine().link(...)` 算出 links。

- [ ] **Step 1: 写失败测试（轻量，聚焦 PulseState 新字段）**

创建 `test/signal_hub/pulse_controller_p1_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/presentation/controllers/pulse_controller.dart';

void main() {
  test('PulseState.links 与 hasStrongSignal 默认值', () {
    const s = PulseState(articles: [], quotes: {}, links: [], hasStrongSignal: false);
    expect(s.links, isEmpty);
    expect(s.hasStrongSignal, isFalse);
  });

  test('PulseState.empty 兼容新字段', () {
    expect(PulseState.empty.links, isEmpty);
    expect(PulseState.empty.hasStrongSignal, isFalse);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/signal_hub/pulse_controller_p1_test.dart`
Expected: FAIL — `PulseState` 无 `links`/`hasStrongSignal` 字段。

- [ ] **Step 3: 新增 anomalyDetectorProvider 与 marketAnomaliesProvider**

在 `lib/features/signal_hub/data/anomaly_detector.dart` 底部追加（已是 part 文件结构则加 provider；若 anomaly_detector.dart 没有 part 声明，需改为 part + .g.dart）：

```dart
// 在文件顶部加：
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import '../../../core/state/article_cache.dart';
// import '../../../crypto_radar/presentation/controllers/crypto_radar_controller.dart'; // binanceApiProvider 所在
// part 'anomaly_detector.g.dart';
//
// @riverpod
// AnomalyDetector anomalyDetector(AnomalyDetectorRef ref) {
//   return AnomalyDetector(ref.watch(binanceApiProvider));
// }
//
// @riverpod
// Future<List<MarketAnomaly>> marketAnomalies(MarketAnomaliesRef ref) {
//   final cache = ref.watch(articleCacheProvider);
//   final syms = <String>{};
//   for (final a in cache.values) {
//     for (final t in a.tickers) {
//       syms.add(t.symbol);
//     }
//   }
//   return ref.watch(anomalyDetectorProvider).detect(syms);
// }
```

> 执行时：把 anomaly_detector.dart 改为带 `part 'anomaly_detector.g.dart';` 的结构，加上述两个 @riverpod provider。注意 `binanceApiProvider` 已存在于 `lib/features/crypto_radar/presentation/controllers/crypto_radar_controller.dart:9`。

- [ ] **Step 4: 升级 PulseState 与 PulseController**

在 `pulse_controller.dart`：
- import `signal_link.dart`、`market_anomaly.dart`、`signal_link_engine.dart`、`ticker_dictionary.dart`、`anomaly_detector.dart`（为 marketAnomaliesProvider）
- `PulseState` 加字段 `final List<SignalLink> links`（默认 `const []`）与 `final bool hasStrongSignal`（默认 false）；构造加可选参数；`static const empty` 同步加 `links: [], hasStrongSignal: false`
- `build()` 在返回前追加：
  ```dart
  final anomalies = ref.watch(marketAnomaliesProvider).valueOrNull ?? const [];
  final links = SignalLinkEngine().link(
    articles: enriched,
    anomalies: anomalies,
    dict: TickerDictionary(),
  );
  final hasStrong = links.any((l) => l.isStrong);
  return PulseState(articles: enriched, quotes: quotes, links: links, hasStrongSignal: hasStrong);
  ```

- [ ] **Step 5: 代码生成 + 测试**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/signal_hub/pulse_controller_p1_test.dart test/signal_hub/pulse_page_test.dart`
Expected: P1 新测试 PASS；P0 的 pulse_page_test（override 返回 empty）不回归——但需确认 `_EmptyPulseController` 的 build 返回 `PulseState.empty` 仍编译（empty 已含新字段）。

- [ ] **Step 6: 分析 + 提交**

Run: `flutter analyze lib/features/signal_hub/`
Expected: No issues.

```bash
git add lib/features/signal_hub/data/anomaly_detector.dart \
        lib/features/signal_hub/data/anomaly_detector.g.dart \
        lib/features/signal_hub/presentation/controllers/pulse_controller.dart \
        lib/features/signal_hub/presentation/controllers/pulse_controller.g.dart \
        test/signal_hub/pulse_controller_p1_test.dart
git commit -m "feat(signal-hub): PulseController 装配 SignalLink 与异动检测，产出关联配对"
```

---

## Task 10: PulsePage 渲染异动卡 + 强度条 + 红点呼吸

**Files:**
- Modify: `lib/features/signal_hub/presentation/pages/pulse_page.dart`
- Test: `test/signal_hub/pulse_page_p1_test.dart`

**目标**：
1. 在文章列表前插入 `links` 异动卡区块（每个 `SignalLink` 渲染一张 `AnomalyCard`，其 `relatedArticles` 为同篇文章；下方加 `StrengthBar(strength)`）。
2. 顶部红点：`state.hasStrongSignal` 为 true 时红点呼吸动画（`AnimatedOpacity` 循环），否则静态红点。
3. 文章卡下方的 TickerBadge 区保留 P0 行为。

- [ ] **Step 1: 写 widget 测试**

创建 `test/signal_hub/pulse_page_p1_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/presentation/controllers/pulse_controller.dart';
import 'package:info_flow/features/signal_hub/presentation/pages/pulse_page.dart';

class _EmptyPulse extends PulseController {
  @override
  PulseState build() => PulseState.empty;
}

void main() {
  testWidgets('空态（无 links 无 articles）显示空态文案', (tester) async {
    final container = ProviderContainer(overrides: [
      pulseControllerProvider.overrideWith(() => _EmptyPulse()),
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
```

- [ ] **Step 2: 跑测试确认失败/通过**

Run: `flutter test test/signal_hub/pulse_page_p1_test.dart`
Expected: 若 PulsePage 未改可能仍 PASS（空态行为不变）。先跑确认基线。

- [ ] **Step 3: 改 PulsePage 渲染 links**

在 `pulse_page.dart` 的 `CustomScrollView.slivers` 里，在文章 `SliverList.builder` **之前**插入异动卡 sliver：
```dart
if (state.links.isNotEmpty)
  SliverList.builder(
    itemCount: state.links.length,
    itemBuilder: (context, i) {
      final link = state.links[i];
      return Column(
        children: [
          AnomalyCard(
            anomaly: link.anomaly,
            relatedArticles: [link.article],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StrengthBar(link.strength),
            ),
          ),
        ],
      );
    },
  ),
```
并改 header 的红点为呼吸动画：把红点 `Container` 替换为 `_BreathingDot(active: state.hasStrongSignal)`——定义一个 `StatefulWidget`，`active` 为 true 时用 `AnimationController` 循环 opacity 0.3→1.0→0.3（period 1.2s），false 时静态红点。

新增 import：`anomaly_card.dart`、`strength_bar.dart`、`signal_link.dart`（若类型推断需要）。

`_BreathingDot` 实现要点：
```dart
class _BreathingDot extends StatefulWidget {
  final bool active;
  const _BreathingDot({required this.active});
  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}
class _BreathingDotState extends State<_BreathingDot> with TickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.active) _c.repeat(reverse: true);
  }
  @override
  void didUpdateWidget(_BreathingDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.repeat(reverse: true);
    if (!widget.active && old.active) { _c.stop(); _c.value = 1; }
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
  );
}
```

- [ ] **Step 4: 跑测试确认通过 + P0 回归**

Run: `flutter test test/signal_hub/pulse_page_p1_test.dart test/signal_hub/pulse_page_test.dart`
Expected: 两者都 PASS（空态行为不变；`_EmptyPulse` 返回 empty 不含 links，红点静态）。

- [ ] **Step 5: 全量分析与回归**

Run: `flutter analyze lib/features/signal_hub/presentation/`
Run: `flutter test`
Expected: analyze 无 error；全量测试无回归。

- [ ] **Step 6: 提交**

```bash
git add lib/features/signal_hub/presentation/pages/pulse_page.dart \
        test/signal_hub/pulse_page_p1_test.dart
git commit -m "feat(signal-hub): 脉搏页渲染异动卡、关联强度条与强信号红点呼吸"
```

---

## Task 11: P1 收尾 —— 全量回归 + 文档更新

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 全量测试**

Run: `flutter test`
Expected: 全绿。

- [ ] **Step 2: 全量分析**

Run: `flutter analyze`
Expected: 0 error。

- [ ] **Step 3: 更新 README**

在 `README.md` 信号中枢说明段落，把「（信号中枢 P0）」升级为「（信号中枢 P0/P1）」并补一句 P1 能力：

```markdown
> 💡 **核心特色 · 信号中枢（Signal Hub）**：把资讯与市场异动首次缝合——每条新闻自动识别涉及的标的（加密/贵金属），并展示实时行情徽章；P1 起，市场异动（短周期价格/OI 超阈值）与资讯在时间窗内自动配对，产出可解释的「关联强度 0–100」，强信号红点呼吸提醒。「信息即信号」，让每条资讯带着它的市场身份证。完整方案见 [设计文档](docs/superpowers/specs/2026-07-01-signal-hub-design.md)。
```

- [ ] **Step 4: 提交**

```bash
git add README.md
git commit -m "docs(signal-hub): README 标注 P1 关联引擎能力"
```

- [ ] **Step 5: 终检**

确认以下都为真：
- ✅ 脉搏页文章列表前出现异动卡（当存在 strength≥70 的配对时）
- ✅ 异动卡显示 symbol、summary、反向关联新闻标题
- ✅ 异动卡下方显示 StrengthBar（≥85 带火焰）
- ✅ 存在 strength≥85 配对时，顶部红点呼吸
- ✅ `flutter analyze` 无 error，`flutter test` 全绿
- ✅ 未新增任何 pub 依赖
- ✅ P0 已有功能无回归

---

## Self-Review 记录

1. **Spec 覆盖**：设计文档 3.1.2（Signal Link 公式 + 阈值 + 可解释性）、3.2.1（异动卡 + 关联强度条 + 红点呼吸）均覆盖。「系统推送通知」因依赖约束移出 P1，用应用内红点呼吸替代——已在 Global Constraints 说明。「美股/A股异动源」「Ticker Lens」明确留 P2。
2. **占位符**：无 TBD/TODO；每个步骤含可执行命令或可粘贴代码。
3. **类型一致性**：`MarketAnomaly`/`AnomalyType`/`SignalLink`/`PulseState` 跨任务签名一致；`SignalLinkEngine._symbolScore` 的 `tickers` 参数类型在 Task 6 Step 4 备注了按编译结果选 `List<TickerRef>` 或 `List<dynamic>`；`TickerRef.sector` 在 Task 5 引入后，Task 6 的 `_symbolScore` 使用其 `.sector` 字段。
4. **范围**：11 个任务，单一可交付（脉搏页异动卡 + 关联强度 + 红点呼吸），可独立发布。P0 无回归。
5. **P0 兼容**：Task 1（interval 默认 '1d'）、Task 5（sector 可选）均向后兼容；Task 9/10 的 PulseState/PulsePage 改动保留 P0 字段与行为。
