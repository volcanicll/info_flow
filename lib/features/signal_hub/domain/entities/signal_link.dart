/// 信号关联结果：一个市场异动信号 ↔ 一篇资讯事件的配对。
///
/// [strength] 为 0–100 的关联强度，由三项可解释分数加权合成：
/// 时间邻近度 × 40% + 标的匹配度 × 30% + 异动剧烈度 × 30%。
class SignalLink {
  final String articleId;
  final String articleTitle;

  /// 异动信号侧
  final String signalCoin; // 'ETH'
  final String direction; // 'long' / 'short'
  final int signalScore;
  final String strategy;

  /// 事件侧命中的标的符号（与 signalCoin 精确/同板块匹配的 ticker）
  final String tickerSymbol;

  /// 0–100 综合关联强度
  final int strength;

  /// 打分明细（0–1），供「为什么关联」查看
  final double timeScore;
  final double matchScore;
  final double intensityScore;

  const SignalLink({
    required this.articleId,
    required this.articleTitle,
    required this.signalCoin,
    required this.direction,
    required this.signalScore,
    required this.strategy,
    required this.tickerSymbol,
    required this.strength,
    required this.timeScore,
    required this.matchScore,
    required this.intensityScore,
  });

  /// 强度分级：强信号 / 中信号 / 弱关联（对应设计阈值 85 / 70）。
  SignalLinkTier get tier {
    if (strength >= 85) return SignalLinkTier.strong;
    if (strength >= 70) return SignalLinkTier.medium;
    return SignalLinkTier.weak;
  }
}

enum SignalLinkTier { strong, medium, weak }
