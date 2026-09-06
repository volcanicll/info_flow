import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/app/theme.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/profile/presentation/pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ProfilePage 渲染链上工具、统计和外观设置', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfilePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('链上工具'), findsWidgets);
    expect(find.text('我的自选 / 收藏池'), findsOneWidget);
    expect(find.text('代币探测与安全审计'), findsOneWidget);
    expect(find.text('加密与异动雷达'), findsOneWidget);
  });
}
