import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../data/models/rht_models.dart';
import '../../data/rht_tape_stream.dart';
import '../../data/smart_money_signals.dart';
import '../controllers/smart_money_controller.dart';
import '../format.dart';
import '../widgets/resonance_section.dart';
import '../widgets/smart_money_panels.dart';
import '../widgets/smart_money_views.dart';

/// 聪明钱终端：App 首页。
///
/// 信息优先级即视觉层级：实盘 Tape 是主角（LIVE 滚动），其后依次为
/// 三源共振新币、抱团跟单链、24H 大户榜；新闻流不在此页（情报 Tab 承接）。
/// 所有金额等宽数字，深色终端基调。
class SmartMoneyTerminalPage extends ConsumerWidget {
  const SmartMoneyTerminalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartMoneyProvider);
    final resonance = ref.watch(smartMoneyResonanceProvider);
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(smartMoneyProvider.notifier).refresh();
            ref.invalidate(smartMoneyResonanceProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _TerminalHeader(conn: state.conn),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Hairline(color: c.hairlineStrong),
              ),
              _TerminalHero(overview: state.overview),
              _SectionHeader(
                kicker: 'LIVE TAPE · 实盘',
                action: '全部',
                onAction: () => context.push('/smart-money'),
              ),
              _TapeTeaser(state: state),
              Hairline(color: c.hairline),
              _SectionHeader(kicker: 'SMART RESONANCE · 三源共振'),
              _ResonanceTeaser(resonance: resonance),
              Hairline(color: c.hairline),
              _SectionHeader(kicker: 'COPY FLOW · 抱团跟单'),
              _FlowTeaser(state: state),
              Hairline(color: c.hairline),
              _SectionHeader(
                kicker: 'TOP TRADERS · 24H 盈亏榜',
                action: '榜单',
                onAction: () => context.push('/smart-money'),
              ),
              _TopTradersTeaser(state: state),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EnterFullTerminal(onTap: () => context.push('/smart-money')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首页头部：kicker + 大标题 + LIVE 徽标 + 雷达入口（庄家雷达扫描页）。
class _TerminalHeader extends StatelessWidget {
  final RhtTapeConn conn;

  const _TerminalHeader({required this.conn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SMART MONEY · ROBINHOOD CHAIN',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: c.accent,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 2),
                Text('聪明钱终端', style: theme.textTheme.displayMedium),
              ],
            ),
          ),
          ConnChip(conn: conn),
          const SizedBox(width: 4),
          IconBtn(
            icon: Icons.radar_rounded,
            onTap: () => context.push('/crypto-radar'),
          ),
        ],
      ),
    );
  }
}

/// 24H 净盈亏主数字：等宽滚动，一眼看到聪明钱今天赚没赚钱。
class _TerminalHero extends StatelessWidget {
  final RhtOverview? overview;

  const _TerminalHero({required this.overview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final o = overview;
    final netUp = (o?.netPnl ?? 0) >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('24H 净盈亏',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: c.inkTertiary, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(
            o == null ? '加载中…' : signedUsd(o.netPnl),
            style: AppTheme.mono(theme.textTheme.displayLarge!.copyWith(
              color: o == null ? c.inkTertiary : (netUp ? c.up : c.down),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            )),
          ),
          const SizedBox(height: 8),
          if (o != null)
            Row(
              children: [
                _HeroStat(label: '胜率', value: '${(o.winRate * 100).toStringAsFixed(0)}%'),
                _HeroStat(label: '成交', value: '${o.fills} 笔'),
                _HeroStat(label: '大户在线', value: '${o.activeTraders} 位'),
                if (o.biggestWin != null)
                  Expanded(
                    child: Text(
                      '最大赢家 ${o.biggestWin!.handle} ${signedUsd(o.biggestWin!.usd)}',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(color: c.up),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary)),
          const SizedBox(height: 1),
          Text(value,
              style: AppTheme.mono(theme.textTheme.labelLarge!
                  .copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

/// 区块头：kicker 小字 + 右侧动作，编辑部栏目语言。
class _SectionHeader extends StatelessWidget {
  final String kicker;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.kicker, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(kicker,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: c.inkSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                )),
          ),
          if (action != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: c.accent)),
                    Icon(Icons.chevron_right_rounded,
                        size: 14, color: c.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tape 预览：最近 8 笔，点击行进完整终端。
class _TapeTeaser extends StatelessWidget {
  final SmartMoneyState state;

  const _TapeTeaser({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.fills.isEmpty) {
      return _TeaserPlaceholder(
        message: state.conn == RhtTapeConn.offline
            ? '实时连接断开，恢复后自动重连'
            : '等待实时成交…',
      );
    }
    return Column(
      children: [
        for (final (i, f) in state.fills.take(8).indexed) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: context.colors.hairline),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/smart-money'),
            child: TapeRow(
              fill: f,
              fresh: state.freshIds.contains(f.id),
            ),
          ),
        ],
      ],
    );
  }
}

/// 共振预览：最多 3 条；空态一句话说明筛选门槛。
class _ResonanceTeaser extends StatelessWidget {
  final AsyncValue<List<SmartResonance>> resonance;

  const _ResonanceTeaser({required this.resonance});

  @override
  Widget build(BuildContext context) {
    return resonance.when(
      data: (items) {
        if (items.isEmpty) {
          return _TeaserPlaceholder(message: '近 2 小时暂无满足共振条件的新币');
        }
        return Column(
          children: [
            for (final r in items.take(3)) ResonanceTile(item: r, dense: true),
          ],
        );
      },
      error: (_, _) => _TeaserPlaceholder(message: '共振扫描暂不可用'),
      loading: () => _TeaserPlaceholder(message: '扫描中…'),
    );
  }
}

/// 跟单链预览：只展示最强一条（跟进人数最多）。
class _FlowTeaser extends StatelessWidget {
  final SmartMoneyState state;

  const _FlowTeaser({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.flows.isEmpty) {
      return const _TeaserPlaceholder(message: '暂无大户抱团链，下拉刷新');
    }
    final chains = [...state.flows]
      ..sort((a, b) => b.followers.length.compareTo(a.followers.length));
    return FlowChainCard(chain: chains.first);
  }
}

/// 大户榜前 3。
class _TopTradersTeaser extends StatelessWidget {
  final SmartMoneyState state;

  const _TopTradersTeaser({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.traders.isEmpty) {
      return const _TeaserPlaceholder(message: '榜单加载中…');
    }
    return Column(
      children: [
        for (final (i, t) in state.traders.take(3).indexed)
          TraderRow(trader: t, rank: i + 1),
      ],
    );
  }
}

class _TeaserPlaceholder extends StatelessWidget {
  final String message;

  const _TeaserPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Text(message,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: context.colors.inkTertiary)),
    );
  }
}

/// 底部入口：进入完整终端（过滤、榜单、平仓战绩、关注）。
class _EnterFullTerminal extends StatelessWidget {
  final VoidCallback onTap;

  const _EnterFullTerminal({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: c.hairlineStrong, width: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('进入完整终端 · 榜单 / 跟单 / 平仓 / 关注',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 16, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}
