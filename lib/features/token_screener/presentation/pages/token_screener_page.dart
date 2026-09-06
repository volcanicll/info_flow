import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/press_scale.dart';import '../../../smart_money/data/models/rht_token.dart';
import '../../../smart_money/data/smart_money_signals.dart';
import '../../../smart_money/presentation/format.dart';
import '../../domain/models/onchain_token.dart';
import '../controllers/token_screener_controller.dart';

class TokenScreenerPage extends ConsumerStatefulWidget {
  const TokenScreenerPage({super.key});

  @override
  ConsumerState<TokenScreenerPage> createState() => _TokenScreenerPageState();
}

class _TokenScreenerPageState extends ConsumerState<TokenScreenerPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(tokenScreenerProvider.notifier).search(val);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tokenScreenerProvider);
    final theme = Theme.of(context);
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCREENER · 链上代币探测',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('代币探测与安全', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                  if (state.loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconBtn(
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        if (state.query.isNotEmpty) {
                          _onSearch(state.query);
                        } else if (state.selectedChain != null) {
                          ref
                              .read(tokenScreenerProvider.notifier)
                              .loadTrending(state.selectedChain!);
                        }
                      },
                    ),
                ],
              ),
            ),
            // 搜索输入框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: c.hairlineStrong, width: 0.8),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '输入合约地址 (CA) 或 代币 Symbol...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: c.inkTertiary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            // 链生态筛选 Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ChainPill(
                      label: 'Solana',
                      chain: ChainType.solana,
                      active: state.selectedChain == ChainType.solana,
                      color: ChainColors.solana,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.solana);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ChainPill(
                      label: 'Base',
                      chain: ChainType.base,
                      active: state.selectedChain == ChainType.base,
                      color: ChainColors.base,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.base);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ChainPill(
                      label: 'BSC',
                      chain: ChainType.bsc,
                      active: state.selectedChain == ChainType.bsc,
                      color: ChainColors.bsc,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.bsc);
                      },
                    ),
                    const SizedBox(width: 8),
                    _ChainPill(
                      label: 'Robinhood',
                      chain: ChainType.robinhood,
                      active: state.selectedChain == ChainType.robinhood,
                      color: ChainColors.robinhood,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.robinhood);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            // 结果列表
            Expanded(
              child: state.loading && state.results.isEmpty
                  ? Center(
                      child: Text(
                        '正在探测链上代币…',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: c.inkTertiary),
                      ),
                    )
                  : state.error != null && state.results.isEmpty
                      ? EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: '探测失败',
                          description: state.error!,
                          actionLabel: '重试',
                          actionIcon: Icons.refresh_rounded,
                          onAction: () => ref
                              .read(tokenScreenerProvider.notifier)
                              .loadTrending(
                                  state.selectedChain ?? ChainType.solana),
                        )
                      : state.results.isEmpty
                          ? const EmptyState(
                              icon: Icons.radar_rounded,
                              title: '未检索到代币',
                              description: '请核对合约地址 (CA) 或尝试直接搜索代币名称',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 32),
                              itemCount: state.results.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final token = state.results[index];
                                return _TokenCard(token: token);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainPill extends StatelessWidget {
  final String label;
  final ChainType chain;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ChainPill({
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

class _TokenCard extends ConsumerWidget {
  final OnChainToken token;
  const _TokenCard({required this.token});

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
                _StatItem(
                  label: 'DEX',
                  value: token.dexId?.toUpperCase() ?? 'DEX',
                ),
                _StatItem(
                  label: '流动性池',
                  value: _formatUsd(token.liquidityUsd),
                ),
                _StatItem(
                  label: '24h 成交额',
                  value: _formatUsd(token.volume24h),
                ),
                _StatItem(
                  label: '24h 买/卖',
                  value: '${token.txns24hBuys}/${token.txns24hSells}',
                ),
              ],
            ),
            if (flow != null) _SmartMoneyStrip(flow: flow),
          ],
        ),
      ),
    );
  }
}

/// 聪明钱动向条：被追踪大户在该代币上的 24h 净买卖与首买人。
class _SmartMoneyStrip extends StatelessWidget {
  final RhtTokenFlow flow;

  const _SmartMoneyStrip({required this.flow});

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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

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
