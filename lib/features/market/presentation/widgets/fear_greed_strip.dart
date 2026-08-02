import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../controllers/fear_greed_controller.dart';
import '../../domain/models/fear_greed_index.dart';

/// 恐惧贪婪指数条：报头下的一行市场情绪，数字 + 档位 + 迷你刻度。
class FearGreedStrip extends ConsumerWidget {
  const FearGreedStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(fearGreedIndexProvider).value;
    if (index == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '市场情绪',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: c.inkTertiary, letterSpacing: 1),
              ),
              const Spacer(),
              Text(
                '${index.value}',
                style: AppTheme.mono(theme.textTheme.titleLarge!
                    .copyWith(color: _bandColor(c, index.band))),
              ),
              const SizedBox(width: 6),
              Text(
                index.classification,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: c.inkSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BandScale(band: index.band),
        ],
      ),
    );
  }

  Color _bandColor(AppColors c, FearGreedBand band) {
    return switch (band) {
      FearGreedBand.extremeFear => c.down,
      FearGreedBand.fear => c.warn,
      FearGreedBand.neutral => c.inkTertiary,
      FearGreedBand.greed => c.up,
      FearGreedBand.extremeGreed => c.up,
    };
  }
}

/// 迷你五档刻度：从「恐慌」到「贪婪」，当前档位填色。
class _BandScale extends StatelessWidget {
  final FearGreedBand band;
  const _BandScale({required this.band});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labels = ['恐慌', '', '中性', '', '贪婪'];
    final colors = [c.down, c.warn, c.inkTertiary, c.up, c.up];
    final activeIndex = band.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 4 ? 3 : 0),
                color: i <= activeIndex ? colors[i] : c.hairline,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Text(
                labels[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : (i == 4 ? TextAlign.right : TextAlign.center),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: i == activeIndex ? colors[i] : c.inkTertiary,
                    ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
