import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/network/api_client.dart';
import 'package:info_flow/core/notifications/notification_service.dart';
import '../../data/crypto_watchlist_store.dart';

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

  CryptoRadarState copyWith({
    ScanStatus? status,
    String? error,
    bool clearError = false,
    List<PoolItem>? poolItems,
    List<TradeSignal>? chaseSignals,
    List<TradeSignal>? combinedSignals,
    List<TradeSignal>? ambushSignals,
    List<OiAlert>? oiAlerts,
    List<CoinData>? heatList,
    List<String>? highlights,
    String? progressMessage,
  }) {
    return CryptoRadarState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      poolItems: poolItems ?? this.poolItems,
      chaseSignals: chaseSignals ?? this.chaseSignals,
      combinedSignals: combinedSignals ?? this.combinedSignals,
      ambushSignals: ambushSignals ?? this.ambushSignals,
      oiAlerts: oiAlerts ?? this.oiAlerts,
      heatList: heatList ?? this.heatList,
      highlights: highlights ?? this.highlights,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }
}

@riverpod
class CryptoRadar extends _$CryptoRadar {
  CryptoRepository get _repo => ref.read(cryptoRepositoryProvider);

  @override
  CryptoRadarState build() {
    _repo.onProgress = (msg) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: ScanStatus.scanning,
        progressMessage: msg,
      );
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

      await _notifyNewSignals(signals);
      // 顺带刷新自选币 OI 异动（轻量，不影响已有信号展示）
      await scanWatchlistOi();
    } catch (e) {
      state = CryptoRadarState(
        status: ScanStatus.error,
        error: mapToAppException(e).message,
      );
    }
  }

  /// 扫描完成后，仅对「新出现」的信号发本地通知，避免重复打扰。
  Future<void> _notifyNewSignals(ScanResult signals) async {
    if (!ref.read(signalNotifyPrefProvider)) return;
    final all = [
      ...signals.chase,
      ...signals.combined,
      ...signals.ambush,
    ];
    if (all.isEmpty) return;

    final fingerprints = all
        .map((s) => '${s.coin}|${s.direction}|${s.score}')
        .toList();
    final fresh = ref
        .read(signalNotifyPrefProvider.notifier)
        .markSeen(fingerprints, category: 'radar');
    if (fresh.isEmpty) return;

    final top = all.take(3)
        .map((s) => '${s.coin} ${s.direction} · ${s.score}分')
        .join('  ');
    await ref.read(notificationServiceProvider).showSignalAlert(
          title: '雷达捕获 ${fresh.length} 个新信号',
          body: top,
          payload: '/crypto-radar',
        );
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

  /// 扫描自选币的 OI 异动（轻量，仅遍历自选列表），
  /// 完成后合并进 state，不覆盖已扫描的信号结果。
  Future<void> scanWatchlistOi() async {
    final watchlist = ref.read(cryptoWatchlistStoreProvider);
    if (watchlist.isEmpty) {
      state = state.copyWith(oiAlerts: const []);
      return;
    }
    // 自选存币种简称（BTC），转为 Binance 合约符号（BTCUSDT）
    final syms = watchlist.map((c) => '${c}USDT').toSet();
    try {
      final alerts = await _repo.scanOiChanges(syms);
      state = state.copyWith(oiAlerts: alerts, clearError: true);
      await _notifyOiAlerts(alerts);
    } catch (e) {
      state = state.copyWith(error: mapToAppException(e).message);
    }
  }

  /// OI 异动通知：指纹 coin|deltaPct 去重，仅提醒新异动。
  Future<void> _notifyOiAlerts(List<OiAlert> alerts) async {
    if (!ref.read(signalNotifyPrefProvider)) return;
    if (alerts.isEmpty) return;

    final fingerprints = alerts
        .map((a) => '${a.coin}|${a.oiDeltaPct.toStringAsFixed(1)}')
        .toList();
    final fresh = ref
        .read(signalNotifyPrefProvider.notifier)
        .markSeen(fingerprints, category: 'radar');
    if (fresh.isEmpty) return;

    final top = alerts.take(3)
        .map((a) => '${a.coin} OI${a.oiDeltaPct >= 0 ? '+' : ''}${a.oiDeltaPct.toStringAsFixed(1)}%')
        .join('  ');
    await ref.read(notificationServiceProvider).showSignalAlert(
          title: '自选持仓异动 ${fresh.length} 项',
          body: top,
          payload: '/crypto-radar',
        );
  }

  void reset() => state = const CryptoRadarState();
}
