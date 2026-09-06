import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/app/theme.dart';
import 'package:info_flow/core/models/article.dart';
import 'package:info_flow/core/state/library_store.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/bookmark/presentation/pages/bookmark_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('BookmarkPage 空态展示与标题渲染', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BookmarkPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('剪报集 · SCRAPBOOK'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('剪报集空空如也'), findsOneWidget);
  });

  testWidgets('BookmarkPage 有文章时正确渲染列表', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await container.read(libraryStoreProvider.notifier).toggleBookmark(
          const Article(
            id: 'b-1',
            feedId: 'f-1',
            feedName: '测试源',
            title: '比特币大涨测试文章',
            url: 'https://example.com/b-1',
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BookmarkPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('比特币大涨测试文章'), findsOneWidget);
  });
}
