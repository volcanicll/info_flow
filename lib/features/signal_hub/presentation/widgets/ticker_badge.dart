import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/ticker_quote.dart';
import '../../domain/entities/ticker_ref.dart';

/// 含实时价格 + 涨跌幅的标的徽章。用于脉搏页与未来的 Ticker Lens。
/// quote 为 null 时显示占位「--」，颜色为中性。
class TickerBadge extends StatelessWidget {
  final TickerRef ref;
  final TickerQuote? quote;
  final VoidCallback? onTap;
  const TickerBadge({super.key, required this.ref, this.quote, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final hasQuote = quote != null;
    final color = !hasQuote
        ? (theme.textTheme.bodySmall?.color ?? Colors.grey)
        : (quote!.changePercent > 0
            ? AppTheme.up(brightness)
            : quote!.changePercent < 0
                ? AppTheme.down(brightness)
                : (theme.textTheme.bodySmall?.color ?? Colors.grey));

    final priceText = hasQuote ? _formatPrice(quote!.price) : '--';
    final chgText = hasQuote
        ? "${quote!.isUp ? '+' : ''}${quote!.changePercent.toStringAsFixed(2)}%"
        : '--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ref.symbol,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
            const SizedBox(width: 6),
            Text(priceText,
                style: TextStyle(
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                )),
            const SizedBox(width: 4),
            Text(chgText,
                style: TextStyle(
                  fontSize: 10,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000) {
      // 千分位
      final s = p.toStringAsFixed(2);
      final parts = s.split('.');
      final left = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$left.${parts[1]}';
    }
    if (p >= 1) return p.toStringAsFixed(2);
    return p.toStringAsFixed(4);
  }
}
