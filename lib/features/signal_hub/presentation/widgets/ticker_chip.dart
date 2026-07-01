import 'package:flutter/material.dart';

import '../../domain/entities/ticker_ref.dart';

/// 轻量标的标签：仅符号，无行情。用于 Feed 页文章卡，保持阅读流纯净。
class TickerChip extends StatelessWidget {
  final TickerRef ref;
  final VoidCallback? onTap;
  const TickerChip({super.key, required this.ref, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '#${ref.symbol}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
