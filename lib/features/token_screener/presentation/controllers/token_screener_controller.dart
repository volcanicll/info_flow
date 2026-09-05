import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/token_screener_repository.dart';
import '../../domain/models/onchain_token.dart';

class TokenScreenerState {
  final bool loading;
  final String query;
  final ChainType? selectedChain;
  final List<OnChainToken> results;
  final String? error;

  const TokenScreenerState({
    this.loading = false,
    this.query = '',
    this.selectedChain,
    this.results = const [],
    this.error,
  });

  TokenScreenerState copyWith({
    bool? loading,
    String? query,
    ChainType? selectedChain,
    List<OnChainToken>? results,
    String? error,
  }) {
    return TokenScreenerState(
      loading: loading ?? this.loading,
      query: query ?? this.query,
      selectedChain: selectedChain ?? this.selectedChain,
      results: results ?? this.results,
      error: error,
    );
  }
}

class TokenScreenerNotifier extends Notifier<TokenScreenerState> {
  TokenScreenerRepository get _repository =>
      ref.read(tokenScreenerRepositoryProvider);

  @override
  TokenScreenerState build() {
    Future.microtask(() => loadTrending(ChainType.solana));
    return const TokenScreenerState();
  }

  Future<void> loadTrending(ChainType chain) async {
    state = state.copyWith(loading: true, selectedChain: chain, error: null);
    try {
      final tokens = await _repository.getTrendingTokens(chain);
      state = state.copyWith(loading: false, results: tokens);
    } catch (e) {
      state = state.copyWith(loading: false, error: '加载失败: $e');
    }
  }

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (state.selectedChain != null) {
        loadTrending(state.selectedChain!);
      }
      return;
    }

    state = state.copyWith(loading: true, query: q, error: null);
    try {
      final tokens = await _repository.searchTokens(q);
      state = state.copyWith(loading: false, results: tokens);
    } catch (e) {
      state = state.copyWith(loading: false, error: '搜索失败: $e');
    }
  }
}

final tokenScreenerProvider =
    NotifierProvider<TokenScreenerNotifier, TokenScreenerState>(
  TokenScreenerNotifier.new,
);
