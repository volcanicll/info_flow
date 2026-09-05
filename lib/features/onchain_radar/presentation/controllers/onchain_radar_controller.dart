import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../token_screener/domain/models/onchain_token.dart';
import '../../data/onchain_radar_repository.dart';

class OnChainRadarState {
  final bool loading;
  final ChainType? chainFilter; // null = 全部
  final RadarSnapshot snapshot;
  final String? error;

  const OnChainRadarState({
    this.loading = false,
    this.chainFilter,
    required this.snapshot,
    this.error,
  });

  OnChainRadarState copyWith({
    bool? loading,
    ChainType? chainFilter,
    bool clearFilter = false,
    RadarSnapshot? snapshot,
    String? error,
  }) {
    return OnChainRadarState(
      loading: loading ?? this.loading,
      chainFilter: clearFilter ? null : (chainFilter ?? this.chainFilter),
      snapshot: snapshot ?? this.snapshot,
      error: error,
    );
  }
}

class OnChainRadarNotifier extends Notifier<OnChainRadarState> {
  OnChainRadarRepository get _repo => ref.read(onChainRadarRepositoryProvider);

  @override
  OnChainRadarState build() {
    Future.microtask(() => load());
    return OnChainRadarState(snapshot: RadarSnapshot.empty());
  }

  Future<void> load({ChainType? filter, bool isRefresh = false}) async {
    state = state.copyWith(
      loading: !isRefresh,
      chainFilter: filter,
      clearFilter: filter == null,
      error: null,
    );

    try {
      final snap = await _repo.fetchRadarSnapshot(filter);
      state = state.copyWith(loading: false, snapshot: snap);
    } catch (e) {
      state = state.copyWith(loading: false, error: '加载雷达失败: $e');
    }
  }

  void selectChain(ChainType? chain) {
    if (state.chainFilter == chain) return;
    load(filter: chain);
  }
}

final onChainRadarProvider =
    NotifierProvider<OnChainRadarNotifier, OnChainRadarState>(
  OnChainRadarNotifier.new,
);
