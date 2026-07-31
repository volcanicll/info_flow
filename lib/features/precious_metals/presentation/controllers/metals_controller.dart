import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/network/api_client.dart';

import '../../data/metals_repository.dart';
import '../../domain/models/metal_price.dart';

part 'metals_controller.g.dart';

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

@riverpod
class Metals extends _$Metals {
  @override
  MetalsState build() => const MetalsState();

  Future<void> loadPrices() async {
    state = const MetalsState(status: MetalsStatus.loading);
    try {
      final prices = await ref.read(metalsRepositoryProvider).fetchPrices();
      state = MetalsState(status: MetalsStatus.done, prices: prices);
    } catch (e) {
      state = MetalsState(
        status: MetalsStatus.error,
        error: mapToAppException(e).message,
      );
    }
  }
}
