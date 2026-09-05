import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/smart_money_watch_store.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../data/datasources/fomo_api.dart';
import '../../data/models/rht_position.dart';
import '../../data/models/rht_token.dart';
import '../../data/models/rht_trader.dart';
import '../format.dart';
import 'trader_detail_sheet.dart';

/// 大户榜时间窗切换：24h 用 robinhoodtrenches 榜，更长窗口用 fomoapi 跨链榜。
class LeaderWindowChips extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChanged;

  const LeaderWindowChips({
    super.key,
    required this.active,
    required this.onChanged,
  });

  static const _windows = [
    ('24h', '24H'),
    ('7d', '7D'),
    ('30d', '30D'),
    ('all', '全部'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          for (final (value, label) in _windows) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(value),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: value == active ? c.ink : c.hairlineStrong,
                    width: value == active ? 1 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: value == active ? c.ink : c.inkTertiary,
                      fontWeight:
                          value == active ? FontWeight.w700 : FontWeight.w400,
                      letterSpacing: 0.5,
                    )),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Spacer(),
          Text(active == '24h' ? 'ROBINHOOD 链' : 'FOMO 全链',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: c.inkTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}

/// fomoapi 跨链榜条目（7d/30d/全部窗口）。点击打开 fomo 主页。
class FomoLeaderRow extends StatelessWidget {
  final FomoLeaderEntry entry;

  const FomoLeaderRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final up = entry.pnlUsd >= 0;

    return InkWell(
      onTap: () => launchUrl(
        Uri.parse('https://fomo.family/profile/${entry.handle}'),
        mode: LaunchMode.externalApplication,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text('${entry.rank}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: c.inkTertiary)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(entry.title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (entry.verified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded,
                            size: 13, color: c.accent),
                      ],
                      const SizedBox(width: 6),
                      Text('${count(entry.followers)}粉',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: c.inkTertiary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${entry.trades}笔 · 成交${usd(entry.volumeUsd)} · 持仓${entry.holdings}个',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: c.inkSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(signedUsd(entry.pnlUsd),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: up ? c.up : c.down,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

/// 面板空态/加载态。
class PanelPlaceholder extends StatelessWidget {
  final String message;

  const PanelPlaceholder({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(message,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: c.inkTertiary)),
      ),
    );
  }
}

/// 仓位状态标签：加仓 / 出货 / 空仓。
class _StateTag extends StatelessWidget {
  final String state;

  const _StateTag(this.state);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final (label, color) = switch (state) {
      'accumulating' => ('加仓', c.up),
      'draining' => ('出货', c.down),
      _ => ('空仓', c.inkTertiary),
    };
    return Text(label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600));
  }
}

/// 大户行：星标关注（后台告警据此推送），点击行查看详情弹层。
class TraderRow extends ConsumerWidget {
  final RhtTrader trader;
  final int rank;

  const TraderRow({super.key, required this.trader, required this.rank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final netUp = trader.netPnl >= 0;
    final watched = ref.watch(smartMoneyWatchStoreProvider).contains(trader.handle);

    return InkWell(
      onTap: () => showTraderDetailSheet(context, ref, trader.handle),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text('$rank',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: c.inkTertiary)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(trader.title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: watched ? c.accent : c.ink,
                            )),
                      ),
                      const SizedBox(width: 6),
                      Text('${count(trader.followers)}粉',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: c.inkTertiary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${trader.fills}笔 · 实现${signedUsd(trader.realizedPnl)}'
                          ' · 浮动${signedUsd(trader.unrealizedPnl)}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: c.inkSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StateTag(trader.state),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(signedUsd(trader.netPnl),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: netUp ? c.up : c.down,
                      fontWeight: FontWeight.w700,
                    )),
                if (trader.winRate != null)
                  Text('胜率 ${(trader.winRate! * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: c.inkTertiary)),
              ],
            ),
            SizedBox(
              width: 40,
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 20,
                onPressed: () => ref
                    .read(smartMoneyWatchStoreProvider.notifier)
                    .toggle(trader.handle),
                icon: Icon(
                  watched ? Icons.star_rounded : Icons.star_border_rounded,
                  color: watched ? c.accent : c.inkTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 已平仓战绩行。
class ClosedRow extends StatelessWidget {
  final RhtClosedPosition pos;

  const ClosedRow({super.key, required this.pos});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final win = pos.pnlUsd >= 0;
    final color = win ? c.up : c.down;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(pos.symbol,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text('${pos.handle} · 持仓${held(pos.holdSeconds)}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: c.inkSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${ago(pos.closedTs)}清仓 · ${pos.buys}买${pos.sells}卖 · 本金${usd(pos.costSold)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: c.inkTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(signedUsd(pos.pnlUsd),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700)),
              Text(pct(pos.pnlPct),
                  style: theme.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 跟单链卡片：领买人 → 跟随者（含滞后时间）。
class FlowChainCard extends StatelessWidget {
  final RhtFlowChain chain;

  const FlowChainCard({super.key, required this.chain});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(chain.symbol,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(
                chain.followers.isEmpty
                    ? '单人建仓 ${usd(chain.totalUsd)}'
                    : '${chain.followers.length} 位大户跟进 · 合计 ${usd(chain.totalUsd)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: chain.followers.isEmpty ? c.inkTertiary : c.accent,
                  fontWeight: chain.followers.isEmpty ? null : FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _FlowPerson(
            name: chain.lead.handle,
            followers: chain.lead.followers,
            amountUsd: chain.lead.usd,
            trailing: '领买 · ${ago(chain.lead.ts)}',
            highlight: true,
          ),
          for (final f in chain.followers)
            _FlowPerson(
              name: f.handle,
              followers: f.followers,
              amountUsd: f.usd,
              trailing:
                  '+${held(f.lagSeconds?.round())}后跟进',
            ),
          if (chain.sinceLeadPct != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '领买至今 ${pct(chain.sinceLeadPct)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: (chain.sinceLeadPct ?? 0) >= 0 ? c.up : c.down,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlowPerson extends StatelessWidget {
  final String name;
  final int followers;
  final double amountUsd;
  final String trailing;
  final bool highlight;

  const _FlowPerson({
    required this.name,
    required this.followers,
    required this.amountUsd,
    required this.trailing,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          if (!highlight) const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$name · ${count(followers)}粉',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: highlight ? c.ink : c.inkSecondary,
                fontWeight: highlight ? FontWeight.w600 : null,
              ),
            ),
          ),
          Text(usd(amountUsd),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: c.inkSecondary)),
          const SizedBox(width: 10),
          Text(trailing,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: highlight ? c.accent : c.inkTertiary)),
        ],
      ),
    );
  }
}

/// 代币净流行。
class TokenFlowRow extends StatelessWidget {
  final RhtTokenFlow flow;

  const TokenFlowRow({super.key, required this.flow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final netUp = flow.netUsd >= 0;
    final sinceBuy = flow.sinceFirstBuyPct;

    return InkWell(
      onTap: () {
        if (flow.pairUrl != null) {
          launchUrl(Uri.parse(flow.pairUrl!), mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(flow.symbol,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text('${flow.traders}位大户 · ${flow.buyers}人买入',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: c.inkSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    flow.firstBuyer == null
                        ? '暂无首买记录'
                        : '首买 ${flow.firstBuyer!.handle} ${count(flow.firstBuyer!.followers)}粉'
                        '${sinceBuy == null ? '' : ' · 首买至今 ${pct(sinceBuy, dp: 0)}'}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: c.inkTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('净${netUp ? '流入' : '流出'} ${usd(flow.netUsd.abs())}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: netUp ? c.up : c.down,
                      fontWeight: FontWeight.w700,
                    )),
                if (flow.change24 != null)
                  Text('24h ${pct(flow.change24, dp: 0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: (flow.change24 ?? 0) >= 0 ? c.up : c.down,
                      )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 列表容器：空态/数据行 + 发丝线分隔。
class PanelList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int index) itemBuilder;
  final String emptyMessage;

  const PanelList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return PanelPlaceholder(message: emptyMessage);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Hairline(color: context.colors.hairline),
      ),
      itemBuilder: (context, i) => itemBuilder(context, items[i], i),
    );
  }
}
