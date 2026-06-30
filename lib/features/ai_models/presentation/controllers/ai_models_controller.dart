import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_models_repository.dart';
import '../../domain/models/ai_model_item.dart';

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

class AiModelsNotifier extends StateNotifier<AiModelsState> {
  final AiModelsRepository _repo;

  AiModelsNotifier(this._repo) : super(const AiModelsState());

  Future<void> loadModels() async {
    state = const AiModelsState(status: AiModelsStatus.loading);
    try {
      final models = await _repo.fetchTrendingModels();
      state = AiModelsState(status: AiModelsStatus.done, models: models);
    } catch (e) {
      state = AiModelsState(status: AiModelsStatus.error, error: e.toString());
    }
  }
}

final aiModelsProvider =
    StateNotifierProvider<AiModelsNotifier, AiModelsState>((ref) {
  return AiModelsNotifier(ref.read(aiModelsRepositoryProvider));
});
