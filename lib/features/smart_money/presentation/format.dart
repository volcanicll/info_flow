import 'package:intl/intl.dart';

/// 聪明钱模块的数字/时间格式化，口径与上游站点一致（紧凑、可扫读）。
final _grouped = NumberFormat('#,##0');

/// 美元紧凑格式：$81,999 / $1.37M / $13.21B。
String usd(double? v) {
  if (v == null || v.isNaN) return '—';
  final a = v.abs();
  if (a >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
  if (a >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
  if (a >= 1e4) return '\$${_grouped.format(v.round())}';
  return '\$${v.toStringAsFixed(2)}';
}

/// 带符号美元：+$739 / -$9,223。
String signedUsd(double? v) {
  if (v == null || v.isNaN) return '—';
  return (v >= 0 ? '+' : '-') + usd(v.abs());
}

/// 微盘价格：0.0288 / 0.000163 / 1.6e-7。
String price(double? v) {
  if (v == null || v.isNaN || v <= 0) return '—';
  if (v >= 1) return v.toStringAsFixed(4);
  if (v >= 0.0001) return v.toStringAsFixed(6);
  return v.toStringAsExponential(2);
}

/// 代币数量紧凑格式：13.7M / 49.2K / 178.13。
String amount(double? v) {
  if (v == null || v.isNaN) return '—';
  final a = v.abs();
  if (a >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
  if (a >= 1) return v.toStringAsFixed(2);
  return v.toStringAsPrecision(3);
}

/// 百分比：+49.4% / -40.9% / +74657%。
String pct(double? v, {int dp = 1}) {
  if (v == null || v.isNaN) return '—';
  return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(dp)}%';
}

/// 粉丝/笔数紧凑格式：49.8K / 463.7K。
String count(int? v) {
  if (v == null) return '—';
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (v >= 1e4) return '${(v / 1e3).toStringAsFixed(1)}K';
  return _grouped.format(v);
}

/// 持仓时长：45s / 12m / 3h / 65d。
String held(int? sec) {
  if (sec == null || sec <= 0) return '—';
  if (sec < 60) return '${sec}s';
  if (sec < 3600) return '${sec ~/ 60}m';
  if (sec < 86400) return '${sec ~/ 3600}h';
  return '${sec ~/ 86400}d';
}

/// 相对时间：刚刚 / 34s前 / 5m前 / 3h前。
String ago(int ts, {int? nowTs}) {
  if (ts <= 0) return '—';
  final now = nowTs ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final diff = now - ts;
  if (diff < 5) return '刚刚';
  if (diff < 60) return '${diff}s前';
  if (diff < 3600) return '${diff ~/ 60}m前';
  if (diff < 86400) return '${diff ~/ 3600}h前';
  return '${diff ~/ 86400}d前';
}

/// 本地时间 HH:mm:ss（成交 tape 用设备时区，避免跨时区换算歧义）。
String clock(int ts) {
  if (ts <= 0) return '—';
  final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return DateFormat('HH:mm:ss').format(t);
}

/// 本地时间 M/d HH:mm（列表里跨日的旧数据用）。
String stamp(int ts) {
  if (ts <= 0) return '—';
  final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return DateFormat('M/d HH:mm').format(t);
}
