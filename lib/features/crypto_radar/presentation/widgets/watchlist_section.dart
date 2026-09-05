import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/crypto_watchlist_store.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/oi_alert.dart';
import '../../data/models/watch_quote.dart';
import '../../data/watchlist_quotes.dart';
import '../controllers/crypto_radar_controller.dart';

/// 自选行情区块：自选币实时报价 + 加星/去星 + 自选 OI 异动。
///
/// 展示在庄家雷达页顶部：星标可即时添加/移除（触觉反馈 + SnackBar），
/// 点击币行进入该币详情页；OI 异动在下方以警示行呈现。
class WatchlistSection extends ConsumerWidget {
  const WatchlistSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final watchlist = ref.watch(cryptoWatchlistStoreProvider);
    final quotesAsync = ref.watch(watchlistQuotesProvider);
    final oiAlerts = ref.watch(cryptoRadarProvider.select((s) => s.oiAlerts));

    if (watchlist.isEmpty) {
      return const _WatchlistEmpty();
    }

    final quotes = quotesAsync.value ?? const <String, WatchQuote>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(kicker: 'WATCH · 自选', title: '我的自选'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            '轻点星标添加/移除，点击币种查看详情',
            style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
          ),
        ),
        for (final coin in watchlist) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Hairline(),
          ),
          _WatchRow(coin: coin, quote: quotes[coin]),
        ],
        if (oiAlerts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Hairline(),
          ),
          ...oiAlerts.map((a) => _OiAlertRow(alert: a)),
        ],
      ],
    );
  }
}

class _WatchlistEmpty extends StatelessWidget {
  const _WatchlistEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Icon(Icons.star_border_rounded, size: 16, color: c.inkTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '还没有自选币，点击下方信号的星标加入关注',
              style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchRow extends ConsumerWidget {
  final String coin;
  final WatchQuote? quote;
  const _WatchRow({required this.coin, required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final watched = ref.watch(
      cryptoWatchlistStoreProvider.select((s) => s.contains(coin)),
    );
    final isUp = (quote?.changePercent ?? 0) >= 0;

    return InkWell(
      onTap: () => context.push('/coin/$coin'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(coin, style: theme.textTheme.titleMedium),
                  const SizedBox(width: 10),
                  if (quote == null)
                    Text('--',
                        style: AppTheme.mono(theme.textTheme.bodyMedium
                            ?.copyWith(color: c.inkTertiary) ??
                            const TextStyle(fontSize: 13)))
                  else
                    Flexible(
                      child: Text(
                        _formatPrice(quote!.price),
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.mono(theme.textTheme.bodyMedium
                                ?.copyWith(color: c.inkSecondary) ??
                            const TextStyle(fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
            if (quote != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${isUp ? '+' : ''}${quote!.changePercent.toStringAsFixed(2)}%',
                  style: AppTheme.mono(theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isUp ? c.up : c.down,
                  )),
                ),
              ),
            IconButton(
              icon: Icon(
                watched ? Icons.star_rounded : Icons.star_border_rounded,
                size: 20,
                color: watched ? c.accent : c.inkTertiary,
              ),
              tooltip: watched ? '移除自选' : '加入自选',
              onPressed: () => _toggleWatch(context, ref, coin, watched),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleWatch(
      BuildContext context, WidgetRef ref, String coin, bool watched) async {
    HapticFeedback.selectionClick();
    await ref.read(cryptoWatchlistStoreProvider.notifier).toggle(coin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(watched ? '已移除 $coin' : '已加入自选 $coin'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  String _formatPrice(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(3);
    return v.toStringAsFixed(5);
  }
}

/// 自选币 OI 异动警示行：币种 + OI 变动幅度 + 资金费率。
class _OiAlertRow extends StatelessWidget {
  final OiAlert alert;
  const _OiAlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final up = alert.oiDeltaPct >= 0;
    return InkWell(
      onTap: () => context.push('/coin/${alert.coin}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: c.warn),
            const SizedBox(width: 8),
            Text(alert.coin, style: theme.textTheme.labelLarge),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'OI ${up ? '+' : ''}${alert.oiDeltaPct.toStringAsFixed(1)}%',
                style: AppTheme.mono(theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: up ? c.up : c.down,
                )),
              ),
            ),
            Text(
              '费率 ${(alert.fundingRate * 100).toStringAsFixed(3)}%',
              style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
