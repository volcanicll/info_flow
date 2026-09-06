import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/models/article.dart';
import 'package:info_flow/core/state/library_store.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Article _sampleArticle(String id) {
  return Article(
    id: id,
    feedId: 'test-feed',
    feedName: 'Test Feed',
    title: '文章 $id',
    url: 'https://example.com/article/$id',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryStore', () {
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

    test('初始状态为空', () {
      final state = container.read(libraryStoreProvider);
      expect(state.bookmarks, isEmpty);
      expect(state.likedIds, isEmpty);
      expect(state.readIds, isEmpty);
    });

    test('toggleBookmark 收藏与取消收藏文章', () async {
      final store = container.read(libraryStoreProvider.notifier);
      final article = _sampleArticle('art-1');

      await store.toggleBookmark(article);
      var state = container.read(libraryStoreProvider);
      expect(state.bookmarks.length, 1);
      expect(state.isBookmarked('art-1'), isTrue);

      await store.toggleBookmark(article);
      state = container.read(libraryStoreProvider);
      expect(state.bookmarks, isEmpty);
      expect(state.isBookmarked('art-1'), isFalse);
    });

    test('toggleLike 点赞与取消点赞', () async {
      final store = container.read(libraryStoreProvider.notifier);

      await store.toggleLike('art-1');
      var state = container.read(libraryStoreProvider);
      expect(state.isLiked('art-1'), isTrue);

      await store.toggleLike('art-1');
      state = container.read(libraryStoreProvider);
      expect(state.isLiked('art-1'), isFalse);
    });

    test('markRead 标记已读', () async {
      final store = container.read(libraryStoreProvider.notifier);

      await store.markRead('art-1');
      var state = container.read(libraryStoreProvider);
      expect(state.isRead('art-1'), isTrue);

      // 重复标记不影响状态
      await store.markRead('art-1');
      state = container.read(libraryStoreProvider);
      expect(state.isRead('art-1'), isTrue);
    });

    test('toggleReadLater 稍后阅读状态切换', () async {
      final store = container.read(libraryStoreProvider.notifier);
      final article = _sampleArticle('art-1');

      await store.toggleReadLater(article);
      var state = container.read(libraryStoreProvider);
      expect(state.readLaterCount, 1);

      await store.toggleReadLater(article);
      state = container.read(libraryStoreProvider);
      expect(state.readLaterCount, 0);
    });
  });
}
