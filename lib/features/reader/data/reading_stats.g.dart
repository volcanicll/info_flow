// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_stats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 阅读统计：已读文章数、累计阅读时长（分钟）、收藏数
///
/// 已读数复用 libraryStore 的 readIds，阅读时长单独累计。

@ProviderFor(ReadingStats)
final readingStatsProvider = ReadingStatsProvider._();

/// 阅读统计：已读文章数、累计阅读时长（分钟）、收藏数
///
/// 已读数复用 libraryStore 的 readIds，阅读时长单独累计。
final class ReadingStatsProvider
    extends $NotifierProvider<ReadingStats, ReadingStatsState> {
  /// 阅读统计：已读文章数、累计阅读时长（分钟）、收藏数
  ///
  /// 已读数复用 libraryStore 的 readIds，阅读时长单独累计。
  ReadingStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingStatsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingStatsHash();

  @$internal
  @override
  ReadingStats create() => ReadingStats();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingStatsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingStatsState>(value),
    );
  }
}

String _$readingStatsHash() => r'e2b56f90d938deafb4a9e7a94fc3a3b68ff0e527';

/// 阅读统计：已读文章数、累计阅读时长（分钟）、收藏数
///
/// 已读数复用 libraryStore 的 readIds，阅读时长单独累计。

abstract class _$ReadingStats extends $Notifier<ReadingStatsState> {
  ReadingStatsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReadingStatsState, ReadingStatsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReadingStatsState, ReadingStatsState>,
              ReadingStatsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
