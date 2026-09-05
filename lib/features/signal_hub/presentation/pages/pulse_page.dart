import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/animated_entrance.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../feed/presentation/widgets/article_row.dart';
import '../../domain/entities/ticker_quote.dart';
import '../../../market/presentation/widgets/fear_greed_strip.dart';
import '../../../onchain_radar/presentation/controllers/onchain_radar_controller.dart';
import '../../../token_screener/domain/models/onchain_token.dart';
import '../controllers/pulse_controller.dart';
import '../widgets/ticker_badge.dart';

/// 链上多链雷达首页：四链聚合 (Solana, Base, BSC, Robinhood) + 实时异动 + Web3 标的情报流。
class PulsePage extends ConsumerWidget {
  const PulsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pulseControllerProvider);
    final radarState = ref.watch(onChainRadarProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(pulseControllerProvider.notifier).refresh();
            await ref
                .read(onChainRadarProvider.notifier)
                .load(filter: radarState.chainFilter, isRefresh: true);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Masthead(
                  theme: theme,
                  selectedChain: radarState.chainFilter,
                  onSelectChain: (chain) {
                    ref.read(onChainRadarProvider.notifier).selectChain(chain);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: FearGreedStrip()),
              // 热门代币横向滚动条 (DexScreener 实时)
              if (radarState.snapshot.trending.isNotEmpty)
                SliverToBoxAdapter(
                  child: _TrendingStrip(tokens: radarState.snapshot.trending),
                ),
              // 巨鲸聪明钱异动
              if (radarState.snapshot.whaleSignals.isNotEmpty)
                SliverToBoxAdapter(
                  child: _WhaleAlertBlock(
                    signals: radarState.snapshot.whaleSignals.take(3).toList(),
                  ),
                ),
              // 情报文章列表
              if (state.articles.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyPulse(theme: theme),
                )
              else
                SliverList.separated(
                  itemCount: state.articles.length,
                  separatorBuilder: (_, _) => const Hairline(),
                  itemBuilder: (context, i) {
                    final a = state.articles[i];
                    return AnimatedEntrance(
                      index: i,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ArticleRow(
                            article: a,
                            onTap: () => context.push('/reader/${a.id}'),
                          ),
                          if (a.tickers.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 14),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: a.tickers.map((t) {
                                  final q = state.quotes[t.symbol];
                                  return TickerBadge(
                                    ref: t,
                                    quote: q is TickerQuote ? q : null,
                                    onTap: () =>
                                        context.push('/coin/${t.symbol}'),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  final ThemeData theme;
  final ChainType? selectedChain;
  final void Function(ChainType?) onSelectChain;

  const _Masthead({
    required this.theme,
    required this.selectedChain,
    required this.onSelectChain,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ON-CHAIN RADAR · 链上雷达',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('多链雷达', style: theme.textTheme.displayMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search_rounded, size: 22),
                tooltip: '检索代币与情报',
              ),
            ],
          ),
        ),
        // 链筛选胶囊
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Pill(
                  label: '全部生态',
                  active: selectedChain == null,
                  color: c.ink,
                  onTap: () => onSelectChain(null),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'Solana',
                  active: selectedChain == ChainType.solana,
                  color: const Color(0xFF14F195),
                  onTap: () => onSelectChain(ChainType.solana),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'Base',
                  active: selectedChain == ChainType.base,
                  color: const Color(0xFF0052FF),
                  onTap: () => onSelectChain(ChainType.base),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'BSC',
                  active: selectedChain == ChainType.bsc,
                  color: const Color(0xFFF3BA2F),
                  onTap: () => onSelectChain(ChainType.bsc),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'Robinhood',
                  active: selectedChain == ChainType.robinhood,
                  color: const Color(0xFF00C805),
                  onTap: () => onSelectChain(ChainType.robinhood),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Hairline(color: c.hairlineStrong),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? color : Colors.grey.withValues(alpha: 0.3),
            width: active ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _TrendingStrip extends StatelessWidget {
  final List<OnChainToken> tokens;
  const _TrendingStrip({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 15, color: Colors.deepOrange),
              const SizedBox(width: 4),
              Text(
                'DEX 热门池子 · 实时',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepOrange.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tokens.take(8).length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final t = tokens[i];
              final isUp = t.priceChange24h >= 0;
              return GestureDetector(
                onTap: () {
                  context.push(
                    '/coin/${t.symbol}?address=${t.address}&chain=${t.chain.id}',
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade50
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.colors.hairlineStrong,
                      width: 0.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            t.symbol,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${isUp ? '+' : ''}${t.priceChange24h.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isUp ? context.colors.up : context.colors.down,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vol \$${(t.volume24h / 1e3).toStringAsFixed(0)}K',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _WhaleAlertBlock extends StatelessWidget {
  final List<dynamic> signals;
  const _WhaleAlertBlock({required this.signals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded,
                    size: 15, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                Text(
                  '巨鲸与聪明钱雷达',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final s in signals)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      '[${s.chain}]',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: c.inkTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.tokenSymbol}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.action} \$${(s.amountUsd / 1e3).toStringAsFixed(0)}K',
                        style: TextStyle(
                          fontSize: 11,
                          color: s.action.contains('买入') ? c.up : c.down,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPulse extends StatelessWidget {
  final ThemeData theme;
  const _EmptyPulse({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq_rounded, size: 44, color: Colors.grey),
            const SizedBox(height: 16),
            Text('暂无链上脉搏', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '下拉刷新获取最新链上情报，或稍后再来查看最新动态',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
