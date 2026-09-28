import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/app/router.dart';
import 'package:info_flow/app/theme.dart';

void main() {
  testWidgets('GoRouter 未知路由展示 404 页面与返回首页按钮', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(goRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            );
          },
        ),
      ),
    );

    // 首页 hero 含骨架屏无限脉冲动画，pumpAndSettle 永不静止，
    // 改用固定时长推进帧（多泵几拍覆盖路由转场与 microtask 延迟）。
    Future<void> settleFrames() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    await settleFrames();

    // 手动跳转至不存在的未知路径
    final BuildContext context = tester.element(find.byType(MaterialApp));
    final router = ProviderScope.containerOf(context).read(goRouterProvider);
    router.go('/unknown-route-404');
    await settleFrames();

    expect(find.text('404 · 页面未找到'), findsOneWidget);
    expect(find.text('返回终端首页'), findsOneWidget);

    // 点击返回终端首页
    await tester.tap(find.text('返回终端首页'));
    await settleFrames();

    expect(find.text('404 · 页面未找到'), findsNothing);
  });
}
