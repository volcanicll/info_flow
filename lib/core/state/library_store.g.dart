// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$libraryStoreHash() => r'13445aab2c4d639a67d5150af01f6804a07a3e08';

/// 用户库状态：收藏 / 点赞 / 已读 / 稍后阅读
///
/// 全部持久化到 SharedPreferences。所有页面 watch 此 provider，
/// 任一处修改自动通知全部 watcher，实现状态联动。
///
/// Copied from [LibraryStore].
@ProviderFor(LibraryStore)
final libraryStoreProvider =
    NotifierProvider<LibraryStore, LibraryState>.internal(
      LibraryStore.new,
      name: r'libraryStoreProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$libraryStoreHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LibraryStore = Notifier<LibraryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
