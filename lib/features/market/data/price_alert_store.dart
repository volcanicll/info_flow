import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/core/logging/logger.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import '../domain/models/price_alert.dart';

part 'price_alert_store.g.dart';

/// 代币价格提醒规则仓库：持久化到 SharedPreferences（JSON 列表）。
///
/// 管理页增删改查与后台告警引擎共用；触发状态同样落盘，
/// 重启后不会把已触发的规则再推一遍。
@Riverpod(keepAlive: true)
class PriceAlertStore extends _$PriceAlertStore {
  static const _kAlerts = 'price_alerts_v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<PriceAlert> build() => _load();

  List<PriceAlert> _load() {
    final raw = _prefs.getString(_kAlerts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return decodePriceAlerts(raw);
    } catch (e) {
      // 历史数据损坏时丢弃而非崩溃：空列表兜底
      ref.read(loggerProvider).w('价格提醒读取失败', error: e);
      return const [];
    }
  }

  Future<void> _persist() async {
    try {
      await _prefs.setString(_kAlerts, encodePriceAlerts(state));
    } catch (e) {
      // 磁盘写入失败不冒泡到 UI：内存状态保留，下次启动回退
      ref.read(loggerProvider).w('价格提醒保存失败', error: e);
    }
  }

  /// 新增提醒。入参非法返回 null（文案见 [validatePriceAlertDraft]）；
  /// 涨跌幅类的基线由调用方传入现价（缺失时不创建，避免永不触发的死规则）。
  PriceAlert? add({
    required String symbol,
    required PriceAlertKind kind,
    double? targetPrice,
    double? changePct,
    double? baselinePrice,
  }) {
    final error = validatePriceAlertDraft(
      symbol: symbol,
      kind: kind,
      targetPrice: targetPrice,
      changePct: changePct,
    );
    if (error != null) return null;
    if ((kind == PriceAlertKind.changeUp ||
            kind == PriceAlertKind.changeDown) &&
        (baselinePrice == null || baselinePrice <= 0)) {
      return null;
    }
    final alert = PriceAlert(
      id: 'pa${DateTime.now().microsecondsSinceEpoch}',
      symbol: symbol.trim().toUpperCase(),
      kind: kind,
      targetPrice: targetPrice,
      changePct: changePct,
      baselinePrice: baselinePrice,
      createdAt: DateTime.now(),
    );
    state = [...state, alert];
    _persist();
    return alert;
  }

  Future<void> remove(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _persist();
  }

  /// 标记触发：停用并记录时间（一次性语义），由告警引擎调用。
  Future<void> markTriggered(String id) async {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(enabled: false, triggeredAt: DateTime.now()) else a,
    ];
    await _persist();
  }

  /// 重新启用：清触发标记、代数自增（通知指纹随之更新，可再次触发）；
  /// 涨跌幅类以 currentPrice 重建基线（无价则沿用原基线）。
  Future<void> reArm(String id, {double? currentPrice}) async {
    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(
            enabled: true,
            clearTriggeredAt: true,
            generation: a.generation + 1,
            baselinePrice:
                currentPrice != null && currentPrice > 0 ? currentPrice : null,
          )
        else
          a,
    ];
    await _persist();
  }

  /// 暂停/恢复监控但不视为触发：不动 triggeredAt 与代数，
  /// 恢复统一走 [reArm]（重建基线、更新指纹）。
  Future<void> setEnabled(String id, {required bool enabled}) async {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(enabled: enabled) else a,
    ];
    await _persist();
  }

  /// 指定币种的提醒数（币详情页铃铛亮灭用）。
  int countForSymbol(String symbol) =>
      state.where((a) => a.symbol == symbol.toUpperCase()).length;
}
