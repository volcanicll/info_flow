import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/crypto_watchlist_store.dart';
import '../../../../shared/widgets/animated_number.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/trade_signal.dart';

/// 信号栏目：栏目头 + 表格化信号行（发丝线分隔，无卡片阴影）。
class RadarSignalSection extends StatelessWidget {
  final String kicker;
  final String title;
  final List<TradeSignal> signals;
  const RadarSignalSection({
    super.key,
    required this.kicker,
    required this.title,
    required this.signals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          kicker: kicker,
          title: title,
          trailing: _CountBadge(count: signals.length),
        ),
        for (var i = 0; i < signals.length; i++) ...[
          if (i > 0) const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Hairline(),
          ),
          RadarSignalRow(signal: signals[i]),
        ],
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Text('$count',
        style: AppTheme.mono(theme.textTheme.titleMedium!.copyWith(
          color: c.inkTertiary,
          fontWeight: FontWeight.w700,
        )));
  }
}

/// 表格化信号行：币种 + 方向 + 策略 + 标签 | 右侧评分（等宽，趋势色）。
/// 行首星标可加入自选，点击币种名进入详情页。
class RadarSignalRow extends ConsumerWidget {
  final TradeSignal signal;
  const RadarSignalRow({super.key, required this.signal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final strong = signal.score >= 65;
    final scoreColor = strong ? c.up : c.warn;
    final watched = ref.watch(
      cryptoWatchlistStoreProvider.select((s) => s.contains(signal.coin)),
    );

    return InkWell(
      onTap: () => context.push('/coin/${signal.coin}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 20, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  watched ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20,
                  color: watched ? c.accent : c.inkTertiary,
                ),
                tooltip: watched ? '移除自选' : '加入自选',
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await ref
                      .read(cryptoWatchlistStoreProvider.notifier)
                      .toggle(signal.coin);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(
                          watched ? '已移除 ${signal.coin}' : '已加入自选 ${signal.coin}'),
                      duration: const Duration(milliseconds: 1200),
                    ));
                },
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(signal.coin, style: theme.textTheme.titleLarge),
                      const SizedBox(width: 8),
                      Text(signal.direction.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: signal.direction.contains('空') ? c.down : c.up,
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(signal.strategy,
                      style: theme.textTheme.bodySmall?.copyWith(color: c.inkSecondary)),
                  if (signal.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: signal.tags.map((t) => RadarSigTag(text: t)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedNumberText(
                  value: signal.score.toDouble(),
                  format: (v) => v.round().toString(),
                  style: AppTheme.mono(theme.textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  )),
                ),
                Text('SCORE',
                    style: theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 信号标签：细线描边，无底色。
class RadarSigTag extends StatelessWidget {
  final String text;
  const RadarSigTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final highlight = text.contains('OI') || text.contains('强趋势');
    final color = highlight ? c.up : c.inkSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: highlight ? c.up : c.hairlineStrong, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text,
          style: theme.textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}
