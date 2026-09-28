import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'hairline.dart';

/// 列表触底分页页脚：三态复用（与情报流页脚同一模式）。
///
/// - [hasMore] == false → 「已经到底了」发丝线收尾；
/// - 加载中 → 小号 spinner；
/// - 等待触底 → 静默占位（撑住滚动位置以便触发加载）。
class LoadMoreFooter extends StatelessWidget {
  final bool hasMore;
  final bool loadingMore;

  const LoadMoreFooter({
    super.key,
    required this.hasMore,
    required this.loadingMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const EndOfListHint();
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// 列表到底提示：发丝线 + 一句话，安静收尾。
class EndOfListHint extends StatelessWidget {
  const EndOfListHint({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: [
          const Expanded(child: Hairline()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '已经到底了',
              style: TextStyle(fontSize: 11.5, color: c.inkTertiary),
            ),
          ),
          const Expanded(child: Hairline()),
        ],
      ),
    );
  }
}
