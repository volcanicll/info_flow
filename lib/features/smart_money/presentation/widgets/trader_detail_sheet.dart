import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../data/models/rht_trader.dart';
import '../../data/smart_money_repository.dart';
import '../format.dart';

/// 大户详情底部弹层：基本盘 + 当前持仓 bags。
Future<void> showTraderDetailSheet(
    BuildContext context, WidgetRef ref, String handle) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TraderDetailSheet(handle: handle),
  );
}

class _TraderDetailSheet extends StatefulWidget {
  final String handle;

  const _TraderDetailSheet({required this.handle});

  @override
  State<_TraderDetailSheet> createState() => _TraderDetailSheetState();
}

class _TraderDetailSheetState extends State<_TraderDetailSheet> {
  RhtTraderDetail? detail;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // 弹层生命周期独立于页面 provider，直接读仓库。
      final repo = ProviderScope.containerOf(context, listen: false)
          .read(smartMoneyRepositoryProvider);
      final d = await repo.fetchTraderDetail(widget.handle);
      if (!mounted) return;
      if (d == null) {
        setState(() => error = '上游未收录该交易员');
        return;
      }
      setState(() => detail = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final d = detail;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: d == null
          ? Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: error != null
                    ? Text(error!,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: c.down))
                    : const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(d.title,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.displaySmall),
                          ),
                          Text('${count(d.followers)}粉',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: c.inkTertiary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '自 ${d.joined} 收录 · ${count(d.numTrades)} 笔成交 · 累计 ${usd(d.volumeUsd)}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: c.inkSecondary),
                      ),
                      if (d.solanaAddress != null)
                        Text('Solana: ${_shorten(d.solanaAddress!)}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: c.inkTertiary)),
                      const SizedBox(height: 10),
                      // 验身份操作行：复制双链地址 + 直达 fomo 主页与
                      // Robinhood Chain 区块浏览器交叉验证
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _VerifyAction(
                            icon: Icons.copy_rounded,
                            label: 'EVM',
                            onTap: () => _copy(context, d.address),
                          ),
                          if (d.solanaAddress != null)
                            _VerifyAction(
                              icon: Icons.copy_rounded,
                              label: 'SOL',
                              onTap: () => _copy(context, d.solanaAddress!),
                            ),
                          if (d.profileUrl.isNotEmpty)
                            _VerifyAction(
                              icon: Icons.open_in_new_rounded,
                              label: 'fomo 主页',
                              onTap: () => launchUrl(
                                  Uri.parse(d.profileUrl),
                                  mode: LaunchMode.externalApplication),
                            ),
                          if (d.address.isNotEmpty)
                            _VerifyAction(
                              icon: Icons.link_rounded,
                              label: 'Blockscout',
                              onTap: () => launchUrl(
                                Uri.parse(
                                    'https://robinhoodchain.blockscout.com/address/${d.address}'),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Text('当前持仓 ${d.bags.length} 个',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('按市值排序',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: c.inkTertiary)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Hairline(color: c.hairline),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _sortedBags(d).length,
                    separatorBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Hairline(color: c.hairline),
                    ),
                    itemBuilder: (context, i) =>
                        _BagRow(bag: _sortedBags(d)[i]),
                  ),
                ),
              ],
            ),
    );
  }

  List<RhtBag> _sortedBags(RhtTraderDetail d) {
    final bags = [...d.bags];
    bags.sort((a, b) => (b.value ?? b.costUsd).compareTo(a.value ?? a.costUsd));
    return bags;
  }

  String _shorten(String addr) =>
      addr.length > 14 ? '${addr.substring(0, 8)}…${addr.substring(addr.length - 4)}' : addr;

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('地址已复制'), duration: Duration(seconds: 1)),
    );
  }
}

/// 验身份小按钮：细边框 + 图标 + 文案。
class _VerifyAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _VerifyAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: c.hairlineStrong, width: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: c.accent),
            const SizedBox(width: 5),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _BagRow extends StatelessWidget {
  final RhtBag bag;

  const _BagRow({required this.bag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final pnl = bag.pnl;
    final color = pnl == null ? c.inkTertiary : (pnl >= 0 ? c.up : c.down);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bag.symbol,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '成本 ${usd(bag.costUsd)} · ${amount(bag.amount)}枚 · ${held(bag.ageSeconds)}前建仓',
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
              Text(pnl == null ? '未定价' : signedUsd(pnl),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700)),
              if (bag.pnlPct != null)
                Text(pct(bag.pnlPct),
                    style: theme.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
