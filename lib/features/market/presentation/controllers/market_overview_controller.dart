import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/network/api_client.dart';
import 'package:info_flow/features/market/data/market_repository.dart';
import 'package:info_flow/features/market/domain/models/market_quote.dart';

part 'market_overview_controller.g.dart';

enum MarketOverviewStatus { idle, loading, done, error }

class MarketOverviewState {
  final MarketOverviewStatus status;
  final String? error;
  final Map<MarketType, List<MarketQuote>> quotes;
  final DateTime? updatedAt;

  const MarketOverviewState({
    this.status = MarketOverviewStatus.idle,
    this.error,
    this.quotes = const {},
    this.updatedAt,
  });

  MarketOverviewState copyWith({
    MarketOverviewStatus? status,
    String? error,
    bool clearError = false,
    Map<MarketType, List<MarketQuote>>? quotes,
    DateTime? updatedAt,
  }) {
    return MarketOverviewState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      quotes: quotes ?? this.quotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@riverpod
class MarketOverview extends _$MarketOverview {
  int _reqSeq = 0;

  @override
  MarketOverviewState build() => const MarketOverviewState();

  Future<void> load() async {
    final seq = ++_reqSeq;
    state = state.copyWith(status: MarketOverviewStatus.loading);
    try {
      final quotes = await ref.read(marketRepositoryProvider).fetchMarketOverview();
      // 已有更新的请求发出时，丢弃本次结果，避免旧响应覆盖新数据
      if (seq != _reqSeq) return;
      state = MarketOverviewState(
        status: MarketOverviewStatus.done,
        quotes: quotes,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (seq != _reqSeq) return;
      state = state.copyWith(
        status: MarketOverviewStatus.error,
        error: mapToAppException(e).message,
      );
    }
  }
}
