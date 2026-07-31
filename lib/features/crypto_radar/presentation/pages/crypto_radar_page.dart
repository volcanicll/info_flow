import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../controllers/crypto_radar_controller.dart';
import '../widgets/radar_signal_list.dart';
import '../widgets/radar_views.dart';

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
    switch (state.status) {
      case ScanStatus.idle:
        return RadarMessageView(
          icon: Icons.radar_rounded,
          title: '雷达待命',
          subtitle: '点击开始扫描全市场资金信号',
          actionLabel: '开始扫描',
          onAction: notifier.startFullScan,
        );
      case ScanStatus.scanning:
        return RadarScanning(message: state.progressMessage);
      case ScanStatus.error:
        return RadarMessageView(
          icon: Icons.error_outline_rounded,
          title: '扫描失败',
          subtitle: state.error ?? '未知错误',
          actionLabel: '重试',
          onAction: notifier.startFullScan,
        );
      case ScanStatus.done:
        return RefreshIndicator(
          onRefresh: notifier.startFullScan,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
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
              if (state.heatList.isNotEmpty)
                RadarHeatSection(heatList: state.heatList),
            ],
          ),
        );
    }
  }
}
