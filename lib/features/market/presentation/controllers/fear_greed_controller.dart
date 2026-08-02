import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/fear_greed_repository.dart';
import '../../domain/models/fear_greed_index.dart';

part 'fear_greed_controller.g.dart';

/// 恐惧贪婪指数：异步拉取，失败返回 null（UI 自行隐藏）。
@riverpod
Future<FearGreedIndex?> fearGreedIndex(Ref ref) async {
  return ref.watch(fearGreedRepositoryProvider).fetchIndex();
}
