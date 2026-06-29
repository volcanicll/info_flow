// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_stats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$readingStatsHash() => r'782510f77175d22c41201b2641976044defc2f20';

/// 阅读统计：已读文章数、累计阅读时长（分钟）、收藏数
///
/// 已读数复用 libraryStore 的 readIds，阅读时长单独累计。
///
/// Copied from [ReadingStats].
@ProviderFor(ReadingStats)
final readingStatsProvider =
    NotifierProvider<ReadingStats, ReadingStatsState>.internal(
      ReadingStats.new,
      name: r'readingStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$readingStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReadingStats = Notifier<ReadingStatsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
