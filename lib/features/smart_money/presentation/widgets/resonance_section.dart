import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/smart_money_signals.dart';
import '../format.dart';

/// 聪明钱共振区块：雷达页里展示「大户首买 ∩ 有效池子 ∩ 审计通过」的三源信号。
///
/// 数据独立于雷达扫描（FutureProvider 自取自缓存），雷达零改动。
class ResonanceSection extends ConsumerWidget {
  const ResonanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(smartMoneyResonanceProvider);
    final theme = Theme.of(context);
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          kicker: 'SMART RESONANCE · 三源共振',
          title: '聪明钱共振',
          trailing: async.isLoading
              ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            '大户首买 × DexScreener 有效池 × GoPlus 审计，三关全过才入选',
            style: theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary),
          ),
        ),
        async.when(
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text('近 2 小时暂无满足共振条件的新币',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: c.inkTertiary)),
              );
            }
            return Column(
              children: [
                for (final (i, r) in items.take(10).indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Hairline(color: c.hairline),
                    ),
                  ResonanceTile(item: r),
                ],
              ],
            );
          },
          error: (e, _) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text('共振扫描暂不可用',
                style:
                    theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary)),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// 共振信号行：终端首页与雷达共振区块共用。
class ResonanceTile extends StatelessWidget {
  final SmartResonance item;
  final bool dense;

  const ResonanceTile({super.key, required this.item, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final change = item.change24h;

    return InkWell(
      onTap: item.pairUrl == null
          ? null
          : () =>
              launchUrl(Uri.parse(item.pairUrl!), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, dense ? 8 : 10, 20, dense ? 8 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: c.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(item.symbol,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${item.firstBuyerHandle} 首买 · ${count(item.firstBuyerFollowers)}粉',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: c.inkSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${count(item.buyers)}位大户买入 ${usd(item.usdIn)} · 流动性${usd(item.liquidityUsd)} · 已过审计',
                    overflow: TextOverflow.ellipsis,
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (change != null && change != 0)
              Text('${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: change > 0 ? c.up : c.down,
                    fontWeight: FontWeight.w700,
                  )),
          ],
        ),
      ),
    );
  }
}
