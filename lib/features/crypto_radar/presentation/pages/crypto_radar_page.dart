import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/auto_refresh.dart';
import '../../../../shared/widgets/editorial_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../controllers/crypto_radar_controller.dart';
import '../../data/watchlist_quotes.dart';
import '../../../smart_money/presentation/widgets/resonance_section.dart';
import '../widgets/radar_signal_list.dart';
import '../widgets/radar_views.dart';
import '../widgets/watchlist_section.dart';

/// 庄家雷达（表格化）：市场概览 + 分组信号表 + 热度榜，扫描进度为文字行。
class CryptoRadarPage extends ConsumerWidget {
  const CryptoRadarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cryptoRadarProvider);
    final notifier = ref.read(cryptoRadarProvider.notifier);
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
                  IconBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHALE RADAR',
                            style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
                        const SizedBox(height: 2),
                        Text('庄家雷达', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                  if (state.status == ScanStatus.scanning)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconBtn(icon: Icons.refresh_rounded, onTap: notifier.startFullScan),
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

  Widget _body(BuildContext context, WidgetRef ref, CryptoRadarState state) {
    final notifier = ref.read(cryptoRadarProvider.notifier);
    final theme = Theme.of(context);
    final c = context.colors;
    switch (state.status) {
      case ScanStatus.idle:
        return EmptyState(
          icon: Icons.radar_rounded,
          title: '雷达待命',
          description: '点击开始扫描全市场资金信号',
          actionLabel: '开始扫描',
          actionIcon: Icons.radar_rounded,
          onAction: notifier.startFullScan,
        );
      case ScanStatus.scanning:
        return RadarScanning(message: state.progressMessage);
      case ScanStatus.error:
        return EmptyState(
          icon: Icons.error_outline_rounded,
          title: '扫描失败',
          description: state.error ?? '未知错误',
          actionLabel: '重试',
          actionIcon: Icons.refresh_rounded,
          onAction: notifier.startFullScan,
        );
      case ScanStatus.done:
        return RefreshIndicator(
          onRefresh: notifier.startFullScan,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              EditorialCard(
                onTap: () => context.push('/smart-money'),
                underline: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SMART MONEY · LIVE TAPE',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: c.accent, letterSpacing: 1.2)),
                          const SizedBox(height: 4),
                          Text('聪明钱实盘 Tape',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('108 个大户钱包逐笔成交 · 跟单链 · 战绩榜',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: c.inkTertiary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.inkTertiary),
                  ],
                ),
              ),
              AutoRefresh(
                interval: const Duration(seconds: 45),
                onRefresh: () async {
                  // 轻量轮询：仅刷新自选报价与 OI 异动，不动全量扫描
                  ref.invalidate(watchlistQuotesProvider);
                  await notifier.scanWatchlistOi();
                },
                child: const WatchlistSection(),
              ),
              RadarOverview(state: state),
              if (state.highlights.isNotEmpty)
                RadarHighlights(highlights: state.highlights),
              if (state.chaseSignals.isNotEmpty)
                RadarSignalSection(
                    kicker: 'CHASE · 费率极端', title: '追多', signals: state.chaseSignals),
              if (state.ambushSignals.isNotEmpty)
                RadarSignalSection(
                    kicker: 'AMBUSH · 低市值 + OI', title: '埋伏', signals: state.ambushSignals),
              if (state.combinedSignals.isNotEmpty)
                RadarSignalSection(
                    kicker: 'COMBINED · 四维评分', title: '综合', signals: state.combinedSignals),
              const ResonanceSection(),
              if (state.heatList.isNotEmpty)
                RadarHeatSection(heatList: state.heatList),
            ],
          ),
        );
    }
  }
}
