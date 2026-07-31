// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 用户库状态：收藏 / 点赞 / 已读 / 稍后阅读
///
/// 全部持久化到 SharedPreferences。所有页面 watch 此 provider，
/// 任一处修改自动通知全部 watcher，实现状态联动。

@ProviderFor(LibraryStore)
final libraryStoreProvider = LibraryStoreProvider._();

/// 用户库状态：收藏 / 点赞 / 已读 / 稍后阅读
///
/// 全部持久化到 SharedPreferences。所有页面 watch 此 provider，
/// 任一处修改自动通知全部 watcher，实现状态联动。
final class LibraryStoreProvider
    extends $NotifierProvider<LibraryStore, LibraryState> {
  /// 用户库状态：收藏 / 点赞 / 已读 / 稍后阅读
  ///
  /// 全部持久化到 SharedPreferences。所有页面 watch 此 provider，
  /// 任一处修改自动通知全部 watcher，实现状态联动。
  LibraryStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryStoreHash();

  @$internal
  @override
  LibraryStore create() => LibraryStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryState>(value),
    );
  }
}

String _$libraryStoreHash() => r'c68a42f5e1f6b3185084b57db49ca24a685975fe';

/// 用户库状态：收藏 / 点赞 / 已读 / 稍后阅读
///
/// 全部持久化到 SharedPreferences。所有页面 watch 此 provider，
/// 任一处修改自动通知全部 watcher，实现状态联动。

abstract class _$LibraryStore extends $Notifier<LibraryState> {
  LibraryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LibraryState, LibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LibraryState, LibraryState>,
              LibraryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
