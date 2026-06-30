import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/metals_repository.dart';
import '../../domain/models/metal_price.dart';

enum MetalsStatus { idle, loading, done, error }

class MetalsState {
  final MetalsStatus status;
  final String? error;
  final List<MetalPrice> prices;

  const MetalsState({
    this.status = MetalsStatus.idle,
    this.error,
    this.prices = const [],
  });
}

class MetalsNotifier extends StateNotifier<MetalsState> {
  final MetalsRepository _repo;

  MetalsNotifier(this._repo) : super(const MetalsState());

  Future<void> loadPrices() async {
    state = const MetalsState(status: MetalsStatus.loading);
    try {
      final prices = await _repo.fetchPrices();
      state = MetalsState(status: MetalsStatus.done, prices: prices);
    } catch (e) {
      state = MetalsState(status: MetalsStatus.error, error: e.toString());
    }
  }
}

final metalsProvider =
    StateNotifierProvider<MetalsNotifier, MetalsState>((ref) {
  return MetalsNotifier(ref.read(metalsRepositoryProvider));
});
