// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 阅读页视图控制器：集中管理正文页的模式/排版/进度状态。
///
/// 字号初始值取全局 [fontSizeProvider]（用户偏好），调整时回写持久化。

@ProviderFor(ReaderController)
final readerControllerProvider = ReaderControllerProvider._();

/// 阅读页视图控制器：集中管理正文页的模式/排版/进度状态。
///
/// 字号初始值取全局 [fontSizeProvider]（用户偏好），调整时回写持久化。
final class ReaderControllerProvider
    extends $NotifierProvider<ReaderController, ReaderViewState> {
  /// 阅读页视图控制器：集中管理正文页的模式/排版/进度状态。
  ///
  /// 字号初始值取全局 [fontSizeProvider]（用户偏好），调整时回写持久化。
  ReaderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readerControllerHash();

  @$internal
  @override
  ReaderController create() => ReaderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReaderViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReaderViewState>(value),
    );
  }
}

String _$readerControllerHash() => r'e83e7e2c6d79f215ce64845e7c900b6c73f9eb7b';

/// 阅读页视图控制器：集中管理正文页的模式/排版/进度状态。
///
/// 字号初始值取全局 [fontSizeProvider]（用户偏好），调整时回写持久化。

abstract class _$ReaderController extends $Notifier<ReaderViewState> {
  ReaderViewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReaderViewState, ReaderViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReaderViewState, ReaderViewState>,
              ReaderViewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
