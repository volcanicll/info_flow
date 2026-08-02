/// 加密货币恐惧与贪婪指数（来自 alternative.me）。
///
/// value 0-100：0 极度恐慌、50 中性、100 极度贪婪。
class FearGreedIndex {
  final int value;
  final String classification;
  final DateTime timestamp;

  const FearGreedIndex({
    required this.value,
    required this.classification,
    required this.timestamp,
  });

  /// 情感分档（用于展示与取色）。
  FearGreedBand get band {
    if (value <= 24) return FearGreedBand.extremeFear;
    if (value <= 44) return FearGreedBand.fear;
    if (value <= 54) return FearGreedBand.neutral;
    if (value <= 74) return FearGreedBand.greed;
    return FearGreedBand.extremeGreed;
  }

  bool get isFear => value < 45;
  bool get isGreed => value > 55;
}

enum FearGreedBand { extremeFear, fear, neutral, greed, extremeGreed }
