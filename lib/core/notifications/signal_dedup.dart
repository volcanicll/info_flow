/// 信号通知去重的纯函数（无 Flutter 依赖，便于单元测试）。
library;

/// 对比待通知指纹与已见指纹，返回其中新增的部分。
/// 指纹 = coin|direction|score，用于跨扫描去重，避免重复打扰。
List<String> diffFreshSignals(
  List<String> incoming,
  List<String> seen,
) {
  return incoming.where((f) => !seen.contains(f)).toList();
}
