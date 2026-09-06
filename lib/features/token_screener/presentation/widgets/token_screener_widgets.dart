import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../smart_money/data/models/rht_token.dart';
import '../../../smart_money/data/smart_money_signals.dart';
import '../../../smart_money/presentation/format.dart';
import '../../domain/models/onchain_token.dart';

class ChainPill extends StatelessWidget {
  final String label;
  final ChainType chain;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const ChainPill({
    super.key,
    required this.label,
    required this.chain,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? color : context.colors.hairlineStrong,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? color : context.colors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TokenCard extends ConsumerWidget {
  final OnChainToken token;
  const TokenCard({super.key, required this.token});

  Color _getChainColor(ChainType chain) {
    switch (chain) {
      case ChainType.solana:
        return ChainColors.solana;
      case ChainType.base:
        return ChainColors.base;
      case ChainType.bsc:
        return ChainColors.bsc;
      case ChainType.robinhood:
        return ChainColors.robinhood;
    }
  }

  String _formatUsd(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  String _formatPrice(double v) {
    if (v >= 1000) return '\$${v.toStringAsFixed(2)}';
    if (v >= 1) return '\$${v.toStringAsFixed(4)}';
    if (v >= 0.0001) return '\$${v.toStringAsFixed(6)}';
    return '\$${v.toStringAsFixed(8)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final chainColor = _getChainColor(token.chain);
    final isUp = token.priceChange24h >= 0;

    // 聪明钱动向：该合约地址出现在 24h 被追踪钱包成交里才显示
    final flowIndex = ref.watch(smartMoneyFlowIndexProvider).value;
    final flow = flowIndex?.byAddress[token.address.toLowerCase()];

    return PressScale(
      onTap: () {
        context.push(
          '/coin/${token.symbol}?address=${token.address}&chain=${token.chain.id}',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.hairlineStrong, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 第一行：链标识 + 代币名称 + 价格 + 24h涨跌
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: chainColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    token.chain.shortName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: chainColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        token.symbol,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          token.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: c.inkTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(token.priceUsd),
                      style: AppTheme.mono(theme.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                    ),
                    Text(
                      '${isUp ? '+' : ''}${token.priceChange24h.toStringAsFixed(2)}%',
                      style: AppTheme.mono(theme.textTheme.labelSmall!.copyWith(
                        color: isUp ? c.up : c.down,
                        fontWeight: FontWeight.w700,
                      )),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 第二行：池子信息 + 流动性 + 24h交易量 + 买卖比
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatItem(
                  label: 'DEX',
                  value: token.dexId?.toUpperCase() ?? 'DEX',
                ),
                StatItem(
                  label: '流动性池',
                  value: _formatUsd(token.liquidityUsd),
                ),
                StatItem(
                  label: '24h 成交额',
                  value: _formatUsd(token.volume24h),
                ),
                StatItem(
                  label: '24h 买/卖',
                  value: '${token.txns24hBuys}/${token.txns24hSells}',
                ),
              ],
            ),
            if (flow != null) SmartMoneyStrip(flow: flow),
          ],
        ),
      ),
    );
  }
}

/// 聪明钱动向条：被追踪大户在该代币上的 24h 净买卖与首买人。
class SmartMoneyStrip extends StatelessWidget {
  final RhtTokenFlow flow;

  const SmartMoneyStrip({super.key, required this.flow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final netUp = flow.netUsd >= 0;
    final fb = flow.firstBuyer;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (netUp ? c.up : c.down).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text('聪明钱',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                )),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${flow.traders}位大户24h净${netUp ? '买入' : '卖出'}'
                '${fb == null ? '' : ' · 首买${fb.handle}'}',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: c.inkSecondary),
              ),
            ),
            Text(
              '${netUp ? '+' : '-'}${usd(flow.netUsd.abs())}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: netUp ? c.up : c.down,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  const StatItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9.5,
            color: c.inkTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.mono(theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          )),
        ),
      ],
    );
  }
}
