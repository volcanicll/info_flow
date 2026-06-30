import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/features/feed/domain/entities/article.dart';

part 'library_store.g.dart';

/// 用户库状态：收藏 / 点赞 / 已读 / 稍后阅读
///
/// 全部持久化到 SharedPreferences。所有页面 watch 此 provider，
/// 任一处修改自动通知全部 watcher，实现状态联动。
@Riverpod(keepAlive: true)
class LibraryStore extends _$LibraryStore {
  static const _kBookmarks = 'lib_bookmarks';
  static const _kLiked = 'lib_liked';
  static const _kRead = 'lib_read';

  SharedPreferences? _prefs;

  @override
  LibraryState build() {
    _load();
    return const LibraryState();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final bookmarksJson = _prefs!.getString(_kBookmarks);
    final liked = _prefs!.getStringList(_kLiked) ?? [];
    final read = _prefs!.getStringList(_kRead) ?? [];

    var bookmarks = <Article>[];
    if (bookmarksJson != null) {
      try {
        final list = jsonDecode(bookmarksJson) as List;
        bookmarks =
            list.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    state = LibraryState(
      bookmarks: bookmarks,
      likedIds: liked.toSet(),
      readIds: read.toSet(),
    );
  }

  // ============ 收藏 ============

  Future<void> toggleBookmark(Article article) async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = List<Article>.from(state.bookmarks);
    final exists = list.any((a) => a.id == article.id);
    if (exists) {
      list.removeWhere((a) => a.id == article.id);
    } else {
      list.insert(0, article);
    }
    state = state.copyWith(bookmarks: list);
    await _prefs!.setString(_kBookmarks, _encodeBookmarks(list));
  }

  // ============ 稍后阅读 ============

  Future<void> toggleReadLater(Article article) async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = List<Article>.from(state.bookmarks);
    final idx = list.indexWhere((a) => a.id == article.id);
    if (idx >= 0) {
      final updated = article.copyWith(isReadLater: !list[idx].isReadLater);
      list[idx] = updated;
    } else {
      list.insert(0, article.copyWith(isReadLater: true));
    }
    state = state.copyWith(bookmarks: list);
    await _prefs!.setString(_kBookmarks, _encodeBookmarks(list));
  }

  // ============ 点赞 ============

  Future<void> toggleLike(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final set = Set<String>.from(state.likedIds);
    if (!set.add(id)) set.remove(id);
    state = state.copyWith(likedIds: set);
    await _prefs!.setStringList(_kLiked, set.toList());
  }

  // ============ 已读 ============

  Future<void> markRead(String id) async {
    if (state.readIds.contains(id)) return;
    _prefs ??= await SharedPreferences.getInstance();
    final set = Set<String>.from(state.readIds)..add(id);
    state = state.copyWith(readIds: set);
    await _prefs!.setStringList(_kRead, set.toList());
  }

  String _encodeBookmarks(List<Article> list) =>
      jsonEncode(list.map((a) => a.toJson()).toList());
}

/// 库状态快照（只读查询方法放在这里，watch 时仍可调用）
class LibraryState {
  final List<Article> bookmarks;
  final Set<String> likedIds;
  final Set<String> readIds;

  const LibraryState({
    this.bookmarks = const [],
    this.likedIds = const {},
    this.readIds = const {},
  });

  int get bookmarkCount => bookmarks.length;
  int get readLaterCount => bookmarks.where((a) => a.isReadLater).length;

  bool isBookmarked(String id) => bookmarks.any((a) => a.id == id);
  bool isLiked(String id) => likedIds.contains(id);
  bool isRead(String id) => readIds.contains(id);

  LibraryState copyWith({
    List<Article>? bookmarks,
    Set<String>? likedIds,
    Set<String>? readIds,
  }) {
    return LibraryState(
      bookmarks: bookmarks ?? this.bookmarks,
      likedIds: likedIds ?? this.likedIds,
      readIds: readIds ?? this.readIds,
    );
  }
}
