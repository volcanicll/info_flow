import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../data/models/rht_models.dart';
import '../../data/rht_tape_stream.dart';
import '../controllers/smart_money_controller.dart';
import '../format.dart';
import 'smart_money_panels.dart';

/// 连接状态徽标：LIVE / 轮询 / 离线。
class ConnChip extends StatelessWidget {
  final RhtTapeConn conn;

  const ConnChip({super.key, required this.conn});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, color) = switch (conn) {
      RhtTapeConn.live => ('LIVE', c.up),
      RhtTapeConn.polling => ('轮询', c.inkSecondary),
      RhtTapeConn.connecting => ('连接中', c.inkTertiary),
      RhtTapeConn.offline => ('离线', c.down),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ) ?? const TextStyle()),
        ],
      ),
    );
  }
}

/// 窗口标签：'24h' -> '24H'，'all' -> '全部'。
String windowLabel(String window) => switch (window) {
      '1h' => '1H',
      '24h' => '24H',
      '7d' => '7D',
      '30d' => '30D',
      'all' => '全部',
      _ => window.toUpperCase(),
    };

/// 时间窗切换 chips：编辑部细边框方块，激活态墨框加粗。
class WindowChipRow extends StatelessWidget {
  final List<(String, String)> windows;
  final String active;
  final ValueChanged<String> onChanged;

  const WindowChipRow({
    super.key,
    required this.windows,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          for (final (value, label) in windows) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(value),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
        ],
      ),
    );
  }
}

/// 总览条：净盈亏为主数字，其余为紧凑格子。标签随时间窗变化。
class OverviewStrip extends StatelessWidget {
  final RhtOverview? overview;

  /// 当前时间窗（'24h' 缺省），用于「24H 净盈亏」标签。
  final String window;

  const OverviewStrip({
    super.key,
    required this.overview,
    this.window = '24h',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final o = overview;
    if (o == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }
    final netUp = o.netPnl >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${windowLabel(window)} 净盈亏',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: c.inkTertiary, letterSpacing: 1.2)),
              const Spacer(),
              Text(
                '${o.fills} 笔 · 买 ${o.buys} / 卖 ${o.sells}',
                style: theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                signedUsd(o.netPnl),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: netUp ? c.up : c.down,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '胜率 ${(o.winRate * 100).toStringAsFixed(0)}% · ${o.activeTraders} 位大户在线',
                  style: theme.textTheme.labelSmall?.copyWith(color: c.inkSecondary),
                ),
              ),
            ],
          ),
          if (o.biggestWin != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '最大赢家 ${o.biggestWin!.handle} ${o.biggestWin!.symbol} '
                    '${signedUsd(o.biggestWin!.usd)}（${pct(o.biggestWin!.pct, dp: 0)}）',
                style: theme.textTheme.labelSmall?.copyWith(color: c.up),
              ),
            ),
          const SizedBox(height: 10),
          Hairline(color: c.hairline),
        ],
      ),
    );
  }
}

/// 分段切换：编辑部风下划线 tab，不做底色块。
class SmartTabBar extends StatelessWidget {
  final SmartTab active;
  final ValueChanged<SmartTab> onChanged;

  const SmartTabBar({super.key, required this.active, required this.onChanged});

  static const _tabs = [
    (SmartTab.tape, '实盘'),
    (SmartTab.traders, '大户'),
    (SmartTab.closed, '平仓'),
    (SmartTab.flow, '跟单'),
    (SmartTab.tokens, '代币'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 20),
            for (final (tab, label) in _tabs) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(tab),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tab == active ? c.ink : c.inkTertiary,
                      fontWeight: tab == active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 22),
            ],
          ],
        ),
        Hairline(color: c.hairline),
      ],
    );
  }
}

/// 实盘 tape：顶部过滤框 + 资产分流 + 成交行列表。
class TapeView extends ConsumerWidget {
  final SmartMoneyState state;

  const TapeView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context);
    final filter = state.filter.trim().toLowerCase();
    final rows = state.fills
        .where((f) => switch (state.assetFilter) {
              TapeAssetFilter.tokens => !f.isStock,
              TapeAssetFilter.stocks => f.isStock,
              TapeAssetFilter.all => true,
            })
        .where((f) =>
            filter.isEmpty ||
            f.symbol.toLowerCase().contains(filter) ||
            f.handle.toLowerCase().contains(filter))
        .toList();

    if (state.fills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.conn == RhtTapeConn.offline) ...[
                Text('连接断开',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('上游服务不可达，恢复后自动重连',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: c.inkTertiary)),
              ] else
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: TextField(
            onChanged: (v) =>
                ref.read(smartMoneyProvider.notifier).setFilter(v),
            decoration: const InputDecoration(
              isDense: true,
              hintText: '过滤代币 / 大户',
              prefixIcon: Icon(Icons.search, size: 18),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        _AssetFilterChips(active: state.assetFilter),
        Expanded(
          child: rows.isEmpty
              ? PanelPlaceholder(message: '该分流暂无成交')
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Hairline(color: c.hairline),
                  ),
                  itemBuilder: (context, i) => TapeRow(
                    fill: rows[i],
                    fresh: state.freshIds.contains(rows[i].id),
                  ),
                ),
        ),
      ],
    );
  }
}

/// tape 资产分流 chips：全部 / 币 / 股。
class _AssetFilterChips extends ConsumerWidget {
  final TapeAssetFilter active;

  const _AssetFilterChips({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
      child: Row(
        children: [
          for (final f in TapeAssetFilter.values) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(smartMoneyProvider.notifier).setAssetFilter(f),
              child: Text(
                switch (f) {
                  TapeAssetFilter.all => '全部',
                  TapeAssetFilter.tokens => '币',
                  TapeAssetFilter.stocks => '股',
                },
                style: theme.textTheme.labelSmall?.copyWith(
                  color: f == active ? c.ink : c.inkTertiary,
                  fontWeight: f == active ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 18),
          ],
          const Spacer(),
          Text('BUY & SELL · 被追踪钱包',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: c.inkTertiary, fontSize: 9.5)),
        ],
      ),
    );
  }
}

/// 单条成交：左侧涨跌色条 + 时间/大户 + 右侧金额/价格。
class TapeRow extends StatelessWidget {
  final RhtFill fill;
  final bool fresh;

  const TapeRow({super.key, required this.fill, required this.fresh});

  static const _bigUsd = 5000;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final color = fill.isBuy ? c.up : c.down;
    final big = fill.usd >= _bigUsd;

    return Container(
      decoration: BoxDecoration(
        // 新到行的轻墨点色：明暗主题下都以 ink 低透明度叠加
        color: fresh ? c.ink.withAlpha(10) : null,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(clock(fill.ts),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: c.inkTertiary, letterSpacing: 0.3)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fill.isBuy ? '买' : '卖',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (fill.isStock) ...[
                      const SizedBox(width: 5),
                      Text('股',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: c.warn,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(width: 5),
                    ] else
                      const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fill.symbol,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight:
                              big ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (fill.isNewPosition) ...[
                      const SizedBox(width: 6),
                      Text('首买',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                    for (final flag in fill.flags.take(1)) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(flag,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: c.inkTertiary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${fill.handle} · ${count(fill.followers)}粉',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                signedUsd(fill.isBuy ? fill.usd : -fill.usd),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: big ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text('@${price(fill.price)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: c.inkTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
