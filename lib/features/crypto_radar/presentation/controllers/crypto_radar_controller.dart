import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/network/api_client.dart';

import '../../data/datasources/binance_api.dart';
import '../../data/models/pool_item.dart';
import '../../data/models/oi_alert.dart';
import '../../data/models/trade_signal.dart';
import '../../data/repositories/crypto_repository.dart';

part 'crypto_radar_controller.g.dart';

final binanceApiProvider = Provider<BinanceApi>((ref) {
  return BinanceApi(ref.watch(dioProvider));
});

final cryptoRepositoryProvider = Provider<CryptoRepository>((ref) {
  return CryptoRepository(ref.read(binanceApiProvider));
});

enum ScanStatus { idle, scanning, done, error }

class CryptoRadarState {
  final ScanStatus status;
  final String? error;
  final List<PoolItem> poolItems;
  final List<TradeSignal> chaseSignals;
  final List<TradeSignal> combinedSignals;
  final List<TradeSignal> ambushSignals;
  final List<OiAlert> oiAlerts;
  final List<CoinData> heatList;
  final List<String> highlights;
  final String progressMessage;

  const CryptoRadarState({
    this.status = ScanStatus.idle,
    this.error,
    this.poolItems = const [],
    this.chaseSignals = const [],
    this.combinedSignals = const [],
    this.ambushSignals = const [],
    this.oiAlerts = const [],
    this.heatList = const [],
    this.highlights = const [],
    this.progressMessage = '',
  });
}

@riverpod
class CryptoRadar extends _$CryptoRadar {
  CryptoRepository get _repo => ref.read(cryptoRepositoryProvider);

  @override
  CryptoRadarState build() {
    _repo.onProgress = (msg) {
      state =
          CryptoRadarState(status: ScanStatus.scanning, progressMessage: msg);
    };
    return const CryptoRadarState();
  }

  Future<void> startFullScan() async {
    state = const CryptoRadarState(
        status: ScanStatus.scanning, progressMessage: '初始化扫描…');
    try {
      final signals = await _repo.scanSignals();

      state = CryptoRadarState(
        status: ScanStatus.done,
        chaseSignals: signals.chase,
        combinedSignals: signals.combined,
        ambushSignals: signals.ambush,
        heatList: signals.heat,
        highlights: signals.highlights,
      );
    } catch (e) {
      state = CryptoRadarState(
        status: ScanStatus.error,
        error: mapToAppException(e).message,
      );
    }
  }

  Future<void> scanPool() async {
    state = const CryptoRadarState(status: ScanStatus.scanning);
    try {
      final items = await _repo.scanAccumulationPool();
      state = CryptoRadarState(
        status: ScanStatus.done,
        poolItems: items,
      );
    } catch (e) {
      state = CryptoRadarState(
        status: ScanStatus.error,
        error: mapToAppException(e).message,
      );
    }
  }

  void reset() => state = const CryptoRadarState();
}
