import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../domain/entities/ticker_quote.dart';
import '../../domain/entities/ticker_ref.dart';

/// 含实时价格 + 涨跌幅的标的徽章（财经报纸风：等宽数字 + 细线描边）。
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
    final neutral = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final hasQuote = quote != null;
    final color = !hasQuote
        ? neutral
        : (quote!.changePercent > 0
            ? AppTheme.up(brightness)
            : quote!.changePercent < 0
                ? AppTheme.down(brightness)
                : neutral);

    final priceText = hasQuote ? _formatPrice(quote!.price) : '--';
    final chgText = hasQuote
        ? "${quote!.isUp ? '+' : ''}${quote!.changePercent.toStringAsFixed(2)}%"
        : '--';

    return PressScale(
      pressedScale: 0.92,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.hairStrong(brightness), width: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ref.symbol,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.textTheme.bodyLarge?.color,
                )),
            const SizedBox(width: 8),
            Text(priceText,
                style: AppTheme.mono(TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color,
                ))),
            const SizedBox(width: 6),
            Text(chgText,
                style: AppTheme.mono(TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ))),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000) {
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
