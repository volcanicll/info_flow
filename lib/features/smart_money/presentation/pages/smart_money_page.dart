import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../controllers/smart_money_controller.dart';
import '../widgets/smart_money_panels.dart';
import '../widgets/smart_money_views.dart';

/// 聪明钱：Robinhood 链被追踪大户的实盘成交、战绩与跟单链。
///
/// tape 走 WS 实时流（断线自动降级轮询），榜单 15s 轻轮询；
/// App 回前台时经 [WidgetsBindingObserver] 增量补拉断线期间的成交。
class SmartMoneyPage extends ConsumerStatefulWidget {
  const SmartMoneyPage({super.key});

  @override
  ConsumerState<SmartMoneyPage> createState() => _SmartMoneyPageState();
}

class _SmartMoneyPageState extends ConsumerState<SmartMoneyPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回前台：WS 往往已被系统断开，增量补拉 + 刷新面板
    if (state == AppLifecycleState.resumed) {
      ref.read(smartMoneyProvider.notifier).resync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartMoneyProvider);
    final notifier = ref.read(smartMoneyProvider.notifier);
    final theme = Theme.of(context);
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SMART MONEY · ROBINHOOD CHAIN',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: c.accent)),
                        const SizedBox(height: 2),
                        Text('聪明钱', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                  ConnChip(conn: state.conn),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  state.error!,
                  style: theme.textTheme.labelSmall?.copyWith(color: c.down),
                ),
              ),
            OverviewStrip(overview: state.overview),
            SmartTabBar(
              active: state.tab,
              onChanged: notifier.setTab,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: notifier.refresh,
                child: _body(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SmartMoneyState state) {
    switch (state.tab) {
      case SmartTab.tape:
        return TapeView(state: state);
      case SmartTab.traders:
        return PanelList(
          items: state.traders,
          emptyMessage: state.panelsLoading ? '加载中…' : '暂无数据，下拉重试',
          itemBuilder: (context, t, i) => TraderRow(trader: t, rank: i + 1),
        );
      case SmartTab.closed:
        return PanelList(
          items: state.closed,
          emptyMessage: state.panelsLoading ? '加载中…' : '暂无数据，下拉重试',
          itemBuilder: (context, p, _) => ClosedRow(pos: p),
        );
      case SmartTab.flow:
        return PanelList(
          items: state.flows,
          emptyMessage: state.panelsLoading ? '加载中…' : '暂无跟单链，下拉重试',
          itemBuilder: (context, f, _) => FlowChainCard(chain: f),
        );
      case SmartTab.tokens:
        return PanelList(
          items: state.tokenFlows,
          emptyMessage: state.panelsLoading ? '加载中…' : '暂无数据，下拉重试',
          itemBuilder: (context, f, _) => TokenFlowRow(flow: f),
        );
    }
  }
}
