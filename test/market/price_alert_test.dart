import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/market/data/price_alert_store.dart';
import 'package:info_flow/features/market/domain/models/price_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

PriceAlert _alert({
  PriceAlertKind kind = PriceAlertKind.priceAbove,
  double? targetPrice = 100,
  double? changePct,
  double? baselinePrice,
  bool enabled = true,
  int generation = 0,
}) {
  return PriceAlert(
    id: 'pa1',
    symbol: 'BTC',
    kind: kind,
    targetPrice: targetPrice,
    changePct: changePct,
    baselinePrice: baselinePrice,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    enabled: enabled,
    generation: generation,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('priceAlertShouldFire', () {
    test('priceAbove：到达目标价及以上触发，之下不触发', () {
      final alert = _alert(kind: PriceAlertKind.priceAbove, targetPrice: 100);
      expect(priceAlertShouldFire(alert, 100), isTrue, reason: '边界值含等号');
      expect(priceAlertShouldFire(alert, 100.01), isTrue);
      expect(priceAlertShouldFire(alert, 99.99), isFalse);
    });

    test('priceBelow：到达目标价及以下触发，之上不触发', () {
      final alert = _alert(kind: PriceAlertKind.priceBelow, targetPrice: 50);
      expect(priceAlertShouldFire(alert, 50), isTrue);
      expect(priceAlertShouldFire(alert, 49.99), isTrue);
      expect(priceAlertShouldFire(alert, 50.01), isFalse);
    });

    test('changeUp：自基线涨幅达到阈值触发', () {
      final alert = _alert(
        kind: PriceAlertKind.changeUp,
        changePct: 5,
        baselinePrice: 100,
      );
      expect(priceAlertShouldFire(alert, 105), isTrue, reason: '边界值含等号');
      expect(priceAlertShouldFire(alert, 110), isTrue);
      expect(priceAlertShouldFire(alert, 104.99), isFalse);
      expect(priceAlertShouldFire(alert, 95), isFalse);
    });

    test('changeDown：自基线跌幅达到阈值触发', () {
      final alert = _alert(
        kind: PriceAlertKind.changeDown,
        changePct: 5,
        baselinePrice: 100,
      );
      expect(priceAlertShouldFire(alert, 95), isTrue);
      expect(priceAlertShouldFire(alert, 80), isTrue);
      expect(priceAlertShouldFire(alert, 95.01), isFalse);
      expect(priceAlertShouldFire(alert, 105), isFalse);
    });

    test('未启用 / 价格非法 / 基线非法一律不触发', () {
      expect(
        priceAlertShouldFire(_alert(enabled: false), 200),
        isFalse,
      );
      expect(priceAlertShouldFire(_alert(), 0), isFalse);
      expect(priceAlertShouldFire(_alert(), -1), isFalse);
      expect(
        priceAlertShouldFire(
          _alert(kind: PriceAlertKind.changeUp, changePct: 5),
          200,
        ),
        isFalse,
        reason: '基线缺失为死规则，永不触发',
      );
      expect(
        priceAlertShouldFire(
          _alert(
            kind: PriceAlertKind.changeDown,
            changePct: 5,
            baselinePrice: 0,
          ),
          200,
        ),
        isFalse,
      );
    });
  });

  group('validatePriceAlertDraft', () {
    test('合法输入返回 null，symbol 归一为大写语义（不校验大小写）', () {
      expect(
        validatePriceAlertDraft(
          symbol: ' btc ',
          kind: PriceAlertKind.priceAbove,
          targetPrice: 100,
        ),
        isNull,
      );
      expect(
        validatePriceAlertDraft(
          symbol: 'PEPE',
          kind: PriceAlertKind.changeDown,
          changePct: 0.5,
        ),
        isNull,
      );
    });

    test('空符号 / 非法字符 / 价格与幅度非法分别报错', () {
      expect(
        validatePriceAlertDraft(
          symbol: '',
          kind: PriceAlertKind.priceAbove,
          targetPrice: 100,
        ),
        '请输入币种符号',
      );
      expect(
        validatePriceAlertDraft(
          symbol: 'BT C!',
          kind: PriceAlertKind.priceAbove,
          targetPrice: 100,
        ),
        isNotNull,
      );
      expect(
        validatePriceAlertDraft(
          symbol: 'BTC',
          kind: PriceAlertKind.priceAbove,
          targetPrice: 0,
        ),
        '请输入大于 0 的目标价格',
      );
      expect(
        validatePriceAlertDraft(
          symbol: 'BTC',
          kind: PriceAlertKind.priceAbove,
        ),
        '请输入大于 0 的目标价格',
        reason: 'price 类必须带目标价',
      );
      expect(
        validatePriceAlertDraft(
          symbol: 'BTC',
          kind: PriceAlertKind.changeUp,
          targetPrice: 100,
        ),
        '请输入大于 0 的涨跌幅',
        reason: '涨跌幅类不应误用目标价',
      );
    });
  });

  group('指纹与描述', () {
    test('指纹含代数：重新启用后同一条规则视为新指纹', () {
      expect(priceAlertFingerprint(_alert()), 'pa|pa1|g0');
      expect(
        priceAlertFingerprint(_alert(generation: 2)),
        'pa|pa1|g2',
      );
    });

    test('描述覆盖四种触发方式', () {
      expect(
        priceAlertDescription(
          _alert(kind: PriceAlertKind.priceAbove, targetPrice: 65000),
        ),
        'BTC 涨破 \$65000.00',
      );
      expect(
        priceAlertDescription(
          _alert(kind: PriceAlertKind.priceBelow, targetPrice: 0.5),
        ),
        'BTC 跌破 \$0.500000',
      );
      expect(
        priceAlertDescription(
          _alert(
            kind: PriceAlertKind.changeUp,
            changePct: 5,
            baselinePrice: 100,
          ),
        ),
        'BTC 自 \$100.0000 上涨 ≥5%',
      );
      expect(
        priceAlertDescription(
          _alert(
            kind: PriceAlertKind.changeDown,
            changePct: 12.5,
            baselinePrice: 100,
          ),
        ),
        'BTC 自 \$100.0000 下跌 ≥12.50%',
      );
    });
  });

  group('JSON 编解码', () {
    test('往返保真：四种种类的字段与触发状态不丢失', () {
      final alerts = [
        _alert(kind: PriceAlertKind.priceAbove, targetPrice: 65000),
        _alert(kind: PriceAlertKind.priceBelow, targetPrice: 0.5),
        _alert(
          kind: PriceAlertKind.changeUp,
          changePct: 5,
          baselinePrice: 100,
        ),
        _alert(
          kind: PriceAlertKind.changeDown,
          changePct: 12.5,
          baselinePrice: 100,
          enabled: false,
          generation: 3,
        ).copyWith(triggeredAt: DateTime.fromMillisecondsSinceEpoch(1)),
      ];
      final decoded = decodePriceAlerts(encodePriceAlerts(alerts));
      expect(decoded.length, alerts.length);
      for (var i = 0; i < alerts.length; i++) {
        expect(decoded[i].id, alerts[i].id);
        expect(decoded[i].symbol, alerts[i].symbol);
        expect(decoded[i].kind, alerts[i].kind);
        expect(decoded[i].targetPrice, alerts[i].targetPrice);
        expect(decoded[i].changePct, alerts[i].changePct);
        expect(decoded[i].baselinePrice, alerts[i].baselinePrice);
        expect(decoded[i].enabled, alerts[i].enabled);
        expect(decoded[i].triggeredAt, alerts[i].triggeredAt);
        expect(decoded[i].generation, alerts[i].generation);
      }
    });

    test('容错解码：脏数据被过滤而非抛出', () {
      // 注意 encodePriceAlerts 产出的是数组，这里取单对象的 JSON 拼脏数据
      final obj = jsonEncode(_alert().toJson());
      final decoded = decodePriceAlerts(
        '[$obj, {"id":"x","symbol":"ETH"}, "junk", '
        '{"id":"y","symbol":"SOL","kind":"nope"}]',
      );
      expect(decoded.length, 1);
      expect(decoded.first.symbol, 'BTC');
      // 非法 JSON 由上层（store._load）捕获，本层按约定抛出
      expect(
        () => decodePriceAlerts('not json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PriceAlertStore', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('add 创建规则并落盘；涨跌幅类缺基线拒绝创建', () async {
      final store = container.read(priceAlertStoreProvider.notifier);

      final a = store.add(
        symbol: 'btc',
        kind: PriceAlertKind.priceAbove,
        targetPrice: 65000,
      );
      expect(a, isNotNull);
      expect(a!.symbol, 'BTC', reason: 'symbol 归一为大写');
      expect(container.read(priceAlertStoreProvider).length, 1);
      expect(prefs.getString('price_alerts_v1'), isNotNull);

      expect(
        store.add(
          symbol: 'ETH',
          kind: PriceAlertKind.changeUp,
          changePct: 5,
        ),
        isNull,
        reason: '涨跌幅类必须带基线',
      );
      expect(
        store.add(
          symbol: 'ETH',
          kind: PriceAlertKind.changeUp,
          changePct: 5,
          baselinePrice: 2000,
        ),
        isNotNull,
      );
      expect(container.read(priceAlertStoreProvider).length, 2);
    });

    test('markTriggered 停用并记录时间；reArm 重新启用并重建基线', () async {
      final store = container.read(priceAlertStoreProvider.notifier);
      final a = store.add(
        symbol: 'BTC',
        kind: PriceAlertKind.changeUp,
        changePct: 5,
        baselinePrice: 100,
      )!;

      await store.markTriggered(a.id);
      var after = container.read(priceAlertStoreProvider).first;
      expect(after.enabled, isFalse);
      expect(after.triggeredAt, isNotNull);

      await store.reArm(a.id, currentPrice: 120);
      after = container.read(priceAlertStoreProvider).first;
      expect(after.enabled, isTrue);
      expect(after.triggeredAt, isNull);
      expect(after.baselinePrice, 120, reason: '以现价重建基线');
      expect(after.generation, 1);

      // 重建基线后按新基线计算：120 涨 5% 即 126 才触发，125 不触发
      expect(priceAlertShouldFire(after, 126), isTrue);
      expect(priceAlertShouldFire(after, 125), isFalse);
    });

    test('setEnabled 仅暂停不动触发态；remove 删除并落盘', () async {
      final store = container.read(priceAlertStoreProvider.notifier);
      final a = store.add(
        symbol: 'BTC',
        kind: PriceAlertKind.priceAbove,
        targetPrice: 65000,
      )!;

      await store.setEnabled(a.id, enabled: false);
      var after = container.read(priceAlertStoreProvider).first;
      expect(after.enabled, isFalse);
      expect(after.triggeredAt, isNull, reason: '暂停不是触发');
      expect(
        priceAlertFingerprint(after),
        'pa|${a.id}|g0',
        reason: '暂停不更新代数，指纹不变',
      );

      await store.remove(a.id);
      expect(container.read(priceAlertStoreProvider), isEmpty);
      expect(container.read(priceAlertStoreProvider.notifier).countForSymbol('BTC'), 0);
    });

    test('重启后从 SharedPreferences 恢复', () async {
      final store = container.read(priceAlertStoreProvider.notifier);
      store.add(
        symbol: 'BTC',
        kind: PriceAlertKind.changeDown,
        changePct: 10,
        baselinePrice: 100,
      );

      // 模拟重启：新容器读同一份 prefs
      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      final restored = container2.read(priceAlertStoreProvider);
      expect(restored.length, 1);
      expect(restored.first.symbol, 'BTC');
      expect(restored.first.baselinePrice, 100);
    });
  });
}
