import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class ArticleCardShimmer extends StatelessWidget {
  const ArticleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final color = brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.06);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.hair(brightness), width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(22, 22, 7, color),
                const SizedBox(width: 8),
                _box(80, 13, 4, color),
                const Spacer(),
                _box(50, 12, 4, color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(null, 16, 4, color),
                      const SizedBox(height: 6),
                      _box(null, 13, 4, color),
                      const SizedBox(height: 4),
                      _box(160, 13, 4, color),
                      const SizedBox(height: 10),
                      _box(60, 18, 8, color),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                _box(112, 88, 12, color),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _box(17, 17, 4, color),
                const SizedBox(width: 5),
                _box(24, 12, 4, color),
                const SizedBox(width: 12),
                _box(17, 17, 4, color),
                const SizedBox(width: 5),
                _box(24, 12, 4, color),
                const SizedBox(width: 12),
                _box(17, 17, 4, color),
                const SizedBox(width: 5),
                _box(24, 12, 4, color),
                const Spacer(),
                _box(17, 17, 4, color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(double? w, double h, double r, Color c) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}
