import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/repositories/crypto_repository.dart';
import '../controllers/crypto_radar_controller.dart';

/// 市场概览：四项统计以等宽数字表格化排布，发丝线分隔。
class RadarOverview extends StatelessWidget {
  final CryptoRadarState state;
  const RadarOverview({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cells = [
      (label: '追多', value: state.chaseSignals.length, color: c.warn),
      (label: '埋伏', value: state.ambushSignals.length, color: c.accent),
      (label: '综合', value: state.combinedSignals.length, color: c.up),
      (label: '热度', value: state.heatList.length, color: c.down),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(kicker: 'MARKET · 实时', title: '市场概览'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0)
                  Hairline(vertical: true, length: 40, color: c.hairlineStrong),
                Expanded(
                  child: _OvCell(
                    label: cells[i].label,
                    value: cells[i].value,
                    color: cells[i].color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OvCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _OvCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Column(
      children: [
        Text('$value',
            style: AppTheme.mono(theme.textTheme.displaySmall?.copyWith(color: color) ??
                theme.textTheme.headlineLarge!.copyWith(color: color))),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: c.inkTertiary)),
      ],
    );
  }
}

/// 精选摘要：项目符号文字行。
class RadarHighlights extends StatelessWidget {
  final List<String> highlights;
  const RadarHighlights({super.key, required this.highlights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final h in highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9, right: 8),
                  child: Container(width: 3, height: 3, color: c.accent),
                ),
                Expanded(child: Text(h, style: theme.textTheme.bodyMedium)),
              ]),
            ),
        ],
      ),
    );
  }
}

/// 热度榜：币种 + 热度 | 涨跌（等宽，趋势色），发丝线分隔。
class RadarHeatSection extends StatelessWidget {
  final List<CoinData> heatList;
  const RadarHeatSection({super.key, required this.heatList});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(kicker: 'HEAT · 热度榜', title: '资金热度'),
        for (var i = 0; i < heatList.length; i++) ...[
          if (i > 0) const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Hairline(),
          ),
          _HeatRow(data: heatList[i]),
        ],
      ],
    );
  }
}

class _HeatRow extends StatelessWidget {
  final CoinData data;
  const _HeatRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final isUp = data.pxChg >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(data.coin, style: theme.textTheme.titleMedium),
                const SizedBox(width: 10),
                Text('热度 ${data.heat.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary)),
              ],
            ),
          ),
          Text('${isUp ? '+' : ''}${data.pxChg.toStringAsFixed(1)}%',
              style: AppTheme.mono(theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: isUp ? c.up : c.down,
              ))),
        ],
      ),
    );
  }
}

/// 扫描进度：文字行 + 细线进度条（替代满屏 spinner）。
class RadarScanning extends StatelessWidget {
  final String message;
  const RadarScanning({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SCANNING', style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
            const SizedBox(height: 12),
            Text(message.isEmpty ? '扫描中…' : message,
                textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: c.hairline,
                color: c.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空闲态与错误态。
class RadarMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  const RadarMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: c.hairlineStrong),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
