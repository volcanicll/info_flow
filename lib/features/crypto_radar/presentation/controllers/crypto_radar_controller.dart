import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/binance_api.dart';
import '../../data/models/pool_item.dart';
import '../../data/models/oi_alert.dart';
import '../../data/models/trade_signal.dart';
import '../../data/repositories/crypto_repository.dart';

final binanceApiProvider = Provider<BinanceApi>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'User-Agent': 'Mozilla/5.0 (compatible; InfoFlow/1.0)'},
  ));
  return BinanceApi(dio);
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

class CryptoRadarNotifier extends StateNotifier<CryptoRadarState> {
  final CryptoRepository _repo;

  CryptoRadarNotifier(this._repo) : super(const CryptoRadarState()) {
    _repo.onProgress = (msg) {
      state = CryptoRadarState(status: ScanStatus.scanning, progressMessage: msg);
    };
  }

  Future<void> startFullScan() async {
    state = const CryptoRadarState(status: ScanStatus.scanning, progressMessage: '初始化扫描…');
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
      state = CryptoRadarState(status: ScanStatus.error, error: e.toString());
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
      state = CryptoRadarState(status: ScanStatus.error, error: e.toString());
    }
  }

  void reset() => state = const CryptoRadarState();
}

final cryptoRadarProvider = StateNotifierProvider<CryptoRadarNotifier, CryptoRadarState>((ref) {
  return CryptoRadarNotifier(ref.read(cryptoRepositoryProvider));
});
