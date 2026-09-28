import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:info_flow/app/theme.dart';
import 'package:info_flow/shared/widgets/load_more_footer.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('hasMore=false 展示「已经到底了」收尾', (tester) async {
    await tester.pumpWidget(_host(const LoadMoreFooter(
      hasMore: false,
      loadingMore: false,
    )));
    expect(find.text('已经到底了'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('加载中展示小号 spinner', (tester) async {
    await tester.pumpWidget(_host(const LoadMoreFooter(
      hasMore: true,
      loadingMore: true,
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('已经到底了'), findsNothing);
  });

  testWidgets('等待触底时静默占位（无 spinner 无提示）', (tester) async {
    await tester.pumpWidget(_host(const LoadMoreFooter(
      hasMore: true,
      loadingMore: false,
    )));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('已经到底了'), findsNothing);
  });
}
