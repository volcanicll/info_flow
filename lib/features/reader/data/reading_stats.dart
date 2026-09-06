import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/core/storage/kv_storage.dart';

part 'reading_stats.g.dart';

/// 阅读统计：已读文章数、累计阅读时长（分钟）、收藏数
///
/// 已读数复用 libraryStore 的 readIds，阅读时长单独累计。
@Riverpod(keepAlive: true)
class ReadingStats extends _$ReadingStats {
  static const _kReadSeconds = 'reading_total_seconds';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ReadingStatsState build() =>
      ReadingStatsState(totalReadSeconds: _prefs.getInt(_kReadSeconds) ?? 0);

  /// 累加阅读时长（秒）
  Future<void> addReadDuration(int seconds) async {
    final next = state.totalReadSeconds + seconds;
    state = state.copyWith(totalReadSeconds: next);
    await _prefs.setInt(_kReadSeconds, next);
  }

  /// 格式化阅读时长，如 "2.5h"、"45min"
  String get formattedDuration {
    final minutes = state.totalReadSeconds ~/ 60;
    if (minutes < 60) return '${minutes}min';
    return '${(minutes / 60).toStringAsFixed(1)}h';
  }
}

class ReadingStatsState {
  final int totalReadSeconds;
  const ReadingStatsState({this.totalReadSeconds = 0});

  ReadingStatsState copyWith({int? totalReadSeconds}) =>
      ReadingStatsState(totalReadSeconds: totalReadSeconds ?? this.totalReadSeconds);
}
