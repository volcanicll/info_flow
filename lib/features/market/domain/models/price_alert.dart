import 'dart:convert';

/// 价格提醒触发方式。
enum PriceAlertKind {
  /// 价格涨到指定值及以上
  priceAbove,

  /// 价格跌到指定值及以下
  priceBelow,

  /// 自基线上涨幅度达到阈值
  changeUp,

  /// 自基线下跌幅度达到阈值
  changeDown,
}

/// 一条代币价格提醒规则。
///
/// 触发语义为一次性：命中后由告警引擎停用并记录 [triggeredAt]，
/// 用户可重新启用（[generation] 自增，通知指纹随之更新，可再次触发）。
/// 涨跌幅类的基线 [baselinePrice] 取创建/重新启用时的现价。
class PriceAlert {
  final String id;

  /// 基础币种大写，如 BTC（行情按 {symbol}USDT 查询）
  final String symbol;
  final PriceAlertKind kind;

  /// priceAbove/priceBelow 的目标价（USDT）
  final double? targetPrice;

  /// changeUp/changeDown 的涨跌幅阈值（正数百分比，如 5 表示 ±5%）
  final double? changePct;

  /// changeUp/changeDown 的基线价
  final double? baselinePrice;
  final DateTime createdAt;

  /// false 时引擎跳过；触发后自动置 false
  final bool enabled;
  final DateTime? triggeredAt;

  /// 重新启用次数，参与通知指纹
  final int generation;

  const PriceAlert({
    required this.id,
    required this.symbol,
    required this.kind,
    this.targetPrice,
    this.changePct,
    this.baselinePrice,
    required this.createdAt,
    this.enabled = true,
    this.triggeredAt,
    this.generation = 0,
  });

  PriceAlert copyWith({
    String? id,
    String? symbol,
    PriceAlertKind? kind,
    double? targetPrice,
    double? changePct,
    double? baselinePrice,
    DateTime? createdAt,
    bool? enabled,
    DateTime? triggeredAt,
    bool clearTriggeredAt = false,
    int? generation,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      kind: kind ?? this.kind,
      targetPrice: targetPrice ?? this.targetPrice,
      changePct: changePct ?? this.changePct,
      baselinePrice: baselinePrice ?? this.baselinePrice,
      createdAt: createdAt ?? this.createdAt,
      enabled: enabled ?? this.enabled,
      triggeredAt: clearTriggeredAt ? null : (triggeredAt ?? this.triggeredAt),
      generation: generation ?? this.generation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'kind': kind.name,
        'targetPrice': targetPrice,
        'changePct': changePct,
        'baselinePrice': baselinePrice,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'enabled': enabled,
        'triggeredAt': triggeredAt?.millisecondsSinceEpoch,
        'generation': generation,
      };

  /// 容错反序列化：字段缺失或非法返回 null，由调用方过滤。
  static PriceAlert? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final symbol = json['symbol']?.toString();
    final kindName = json['kind']?.toString();
    if (id == null ||
        id.isEmpty ||
        symbol == null ||
        symbol.isEmpty ||
        kindName == null) {
      return null;
    }
    final kind = PriceAlertKind.values
        .where((k) => k.name == kindName)
        .firstOrNull;
    if (kind == null) return null;
    final createdAtMs = (json['createdAt'] as num?)?.toInt() ?? 0;
    return PriceAlert(
      id: id,
      symbol: symbol.toUpperCase(),
      kind: kind,
      targetPrice: (json['targetPrice'] as num?)?.toDouble(),
      changePct: (json['changePct'] as num?)?.toDouble(),
      baselinePrice: (json['baselinePrice'] as num?)?.toDouble(),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      enabled: (json['enabled'] as bool?) ?? true,
      triggeredAt: json['triggeredAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (json['triggeredAt'] as num).toInt()),
      generation: (json['generation'] as num?)?.toInt() ?? 0,
    );
  }

  static PriceAlert? fromJsonRaw(Object? raw) {
    return raw is Map<String, dynamic> ? fromJson(raw) : null;
  }

  @override
  bool operator ==(Object other) =>
      other is PriceAlert &&
      other.id == id &&
      other.generation == generation &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, generation, enabled);
}

/// 判断提醒在当前价下是否应触发（纯函数）。
///
/// 未启用、价格非法、基线缺失/非法、阈值缺失时一律不触发。
bool priceAlertShouldFire(PriceAlert alert, double currentPrice) {
  if (!alert.enabled || currentPrice <= 0) return false;
  switch (alert.kind) {
    case PriceAlertKind.priceAbove:
      final t = alert.targetPrice;
      return t != null && t > 0 && currentPrice >= t;
    case PriceAlertKind.priceBelow:
      final t = alert.targetPrice;
      return t != null && t > 0 && currentPrice <= t;
    case PriceAlertKind.changeUp:
      final b = alert.baselinePrice;
      final pct = alert.changePct;
      if (b == null || b <= 0 || pct == null || pct <= 0) return false;
      return (currentPrice - b) / b * 100 >= pct;
    case PriceAlertKind.changeDown:
      final b = alert.baselinePrice;
      final pct = alert.changePct;
      if (b == null || b <= 0 || pct == null || pct <= 0) return false;
      return (currentPrice - b) / b * 100 <= -pct;
  }
}

/// 新建提醒的入参校验（纯函数）：返回错误文案，合法返回 null。
/// symbol 接受任意大小写，内部归一为大写。
String? validatePriceAlertDraft({
  required String symbol,
  required PriceAlertKind kind,
  double? targetPrice,
  double? changePct,
}) {
  final sym = symbol.trim().toUpperCase();
  if (sym.isEmpty) return '请输入币种符号';
  if (!RegExp(r'^[A-Z0-9]{2,15}$').hasMatch(sym)) {
    return '币种符号格式不对，如 BTC / PEPE';
  }
  final isPriceKind =
      kind == PriceAlertKind.priceAbove || kind == PriceAlertKind.priceBelow;
  if (isPriceKind) {
    if (targetPrice == null || targetPrice <= 0) return '请输入大于 0 的目标价格';
  } else {
    if (changePct == null || changePct <= 0) return '请输入大于 0 的涨跌幅';
  }
  return null;
}

/// 通知指纹：`pa|id|代数`。重新启用时代数自增，同一条规则可再次触发。
String priceAlertFingerprint(PriceAlert alert) =>
    'pa|${alert.id}|g${alert.generation}';

/// 提醒的一句话描述（列表展示与通知正文共用）。
String priceAlertDescription(PriceAlert alert) {
  switch (alert.kind) {
    case PriceAlertKind.priceAbove:
      return '${alert.symbol} 涨破 ${formatAlertPrice(alert.targetPrice ?? 0)}';
    case PriceAlertKind.priceBelow:
      return '${alert.symbol} 跌破 ${formatAlertPrice(alert.targetPrice ?? 0)}';
    case PriceAlertKind.changeUp:
      return '${alert.symbol} 自 ${formatAlertPrice(alert.baselinePrice ?? 0)} '
          '上涨 ≥${_pct(alert.changePct)}%';
    case PriceAlertKind.changeDown:
      return '${alert.symbol} 自 ${formatAlertPrice(alert.baselinePrice ?? 0)} '
          '下跌 ≥${_pct(alert.changePct)}%';
  }
}

String _pct(double? v) =>
    v == null ? '--' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

/// 价格展示：按量级取小数位，等宽排版场景共用。
String formatAlertPrice(double v) {
  if (v >= 1000) return '\$${v.toStringAsFixed(2)}';
  if (v >= 1) return '\$${v.toStringAsFixed(4)}';
  if (v >= 0.0001) return '\$${v.toStringAsFixed(6)}';
  return '\$${v.toStringAsFixed(8)}';
}

/// 提醒列表的持久化编解码（纯函数，便于单测）。
String encodePriceAlerts(List<PriceAlert> alerts) =>
    jsonEncode(alerts.map((a) => a.toJson()).toList());

List<PriceAlert> decodePriceAlerts(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return decoded
      .map(PriceAlert.fromJsonRaw)
      .whereType<PriceAlert>()
      .toList();
}
