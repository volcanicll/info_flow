import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/network/api_client.dart';

import '../../data/ai_models_repository.dart';
import '../../domain/models/ai_model_item.dart';

part 'ai_models_controller.g.dart';

enum AiModelsStatus { idle, loading, done, error }

class AiModelsState {
  final AiModelsStatus status;
  final String? error;
  final List<AiModelItem> models;

  const AiModelsState({
    this.status = AiModelsStatus.idle,
    this.error,
    this.models = const [],
  });
}

@riverpod
class AiModels extends _$AiModels {
  @override
  AiModelsState build() => const AiModelsState();

  Future<void> loadModels() async {
    state = const AiModelsState(status: AiModelsStatus.loading);
    try {
      final models =
          await ref.read(aiModelsRepositoryProvider).fetchTrendingModels();
      state = AiModelsState(status: AiModelsStatus.done, models: models);
    } catch (e) {
      state = AiModelsState(
        status: AiModelsStatus.error,
        error: mapToAppException(e).message,
      );
    }
  }
}
