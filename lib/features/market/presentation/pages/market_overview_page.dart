import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/auto_refresh.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/fear_greed_strip.dart';
import '../controllers/market_overview_controller.dart';
import '../../domain/models/market_quote.dart';

/// 市场总览：加密主导币 + 恐惧贪婪情绪 + A股/美股/港股，一次拉全。
///
/// 行情数字等宽排版（AppTheme.mono），涨跌用趋势色；下拉刷新。
class MarketOverviewPage extends ConsumerWidget {
  const MarketOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketOverviewProvider);
    final notifier = ref.read(marketOverviewProvider.notifier);
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
                        Text('MARKET · 总览',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: c.accent)),
                        const SizedBox(height: 2),
                        Text('市场总览', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                  if (state.status == MarketOverviewStatus.loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconBtn(
                        icon: Icons.refresh_rounded, onTap: notifier.load),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            Expanded(child: _body(context, ref, state)),
          ],
        ),
      ),
    );
  }

  Widget _body(
      BuildContext context, WidgetRef ref, MarketOverviewState state) {
    final theme = Theme.of(context);
    final c = context.colors;
    switch (state.status) {
      case MarketOverviewStatus.idle:
        return Center(
          child: FilledButton.icon(
            onPressed: ref.read(marketOverviewProvider.notifier).load,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('加载市场数据'),
          ),
        );
      case MarketOverviewStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 44, color: c.hairlineStrong),
                const SizedBox(height: 16),
                Text('加载失败', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(state.error ?? '未知错误',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: ref.read(marketOverviewProvider.notifier).load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      case MarketOverviewStatus.done:
      case MarketOverviewStatus.loading:
        final quotes = state.quotes;
        return AutoRefresh(
          interval: const Duration(seconds: 60),
          onRefresh: ref.read(marketOverviewProvider.notifier).load,
          child: RefreshIndicator(
            onRefresh: ref.read(marketOverviewProvider.notifier).load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (state.updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                    child: Text(
                      '更新于 ${_time(state.updatedAt!)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: c.inkTertiary),
                    ),
                  ),
                const FearGreedStrip(),
                _QuoteGroup(
                  title: '加密货币',
                  kicker: 'CRYPTO · 主导币',
                  quotes: quotes[MarketType.crypto] ?? const [],
                  onTap: (q) => context.push('/coin/${q.symbol}'),
                ),
                _QuoteGroup(
                  title: 'A股指数',
                  kicker: 'CN · 指数',
                  quotes: quotes[MarketType.cnStock] ?? const [],
                ),
                _QuoteGroup(
                  title: '美股',
                  kicker: 'US · 龙头',
                  quotes: quotes[MarketType.usStock] ?? const [],
                ),
                _QuoteGroup(
                  title: '港股',
                  kicker: 'HK · 权重',
                  quotes: quotes[MarketType.hkStock] ?? const [],
                ),
              ],
            ),
          ),
        );
    }
  }

  String _time(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _QuoteGroup extends StatelessWidget {
  final String title;
  final String kicker;
  final List<MarketQuote> quotes;
  final void Function(MarketQuote)? onTap;

  const _QuoteGroup({
    required this.title,
    required this.kicker,
    required this.quotes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (quotes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(kicker: kicker, title: title),
        for (var i = 0; i < quotes.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(),
            ),
          _QuoteRow(quote: quotes[i], onTap: onTap),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _QuoteRow extends StatelessWidget {
  final MarketQuote quote;
  final void Function(MarketQuote)? onTap;

  const _QuoteRow({required this.quote, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final isUp = quote.changePercent > 0;

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(quote),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quote.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(quote.symbol,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: c.inkTertiary)),
                ],
              ),
            ),
            Text(
              _formatPrice(quote.price),
              style: AppTheme.mono(theme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 72,
              child: Text(
                '${isUp ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                textAlign: TextAlign.right,
                style: AppTheme.mono(theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUp ? c.up : c.down,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(3);
    return v.toStringAsFixed(5);
  }
}
