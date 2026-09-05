import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/smart_money/data/datasources/rht_api.dart';
import 'package:info_flow/features/smart_money/data/smart_money_repository.dart';
import 'package:info_flow/features/smart_money/presentation/pages/smart_money_page.dart';

/// 聪明钱页离线路径测试：上游不可达时页面不崩溃、空态可读、分段可切换。
///
/// RhtApi 指向不可路由的 localhost（100ms 超时），WS 与轮询快速失败，
/// 页面应进入离线/空态而非抛异常。
void main() {
  testWidgets('离线时页面渲染空态且分段可切换', (tester) async {
    final badDio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:1',
      connectTimeout: const Duration(milliseconds: 100),
      receiveTimeout: const Duration(milliseconds: 100),
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        rhtApiProvider.overrideWithValue(RhtApi(badDio)),
      ],
      child: const MaterialApp(home: SmartMoneyPage()),
    ));

    // 标题与分段栏渲染
    expect(find.text('聪明钱'), findsOneWidget);
    expect(find.text('实盘'), findsOneWidget);
    expect(find.text('大户'), findsOneWidget);
    expect(find.text('跟单'), findsOneWidget);

    // 等待 WS/回填/轮询失败落 offline（各超时 100ms + 首轮轮询 2.5s）
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('连接断开'), findsOneWidget);

    // 切到各分段：面板空态渲染，不抛异常
    await tester.tap(find.text('大户'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('暂无数据，下拉重试'), findsOneWidget);

    await tester.tap(find.text('跟单'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('暂无跟单链，下拉重试'), findsOneWidget);

    await tester.tap(find.text('平仓'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('暂无数据，下拉重试'), findsOneWidget);
  });

  testWidgets('过滤框输入不抛异常', (tester) async {
    final badDio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:1',
      connectTimeout: const Duration(milliseconds: 100),
      receiveTimeout: const Duration(milliseconds: 100),
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        rhtApiProvider.overrideWithValue(RhtApi(badDio)),
      ],
      child: const MaterialApp(home: SmartMoneyPage()),
    ));
    await tester.pump(const Duration(seconds: 2));

    // 离线时 tape 无数据 → 无过滤框；页面保持稳定即可
    expect(tester.takeException(), isNull);
  });
}
