import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/repositories/crypto_repository.dart';
import '../controllers/crypto_radar_controller.dart';

class CryptoRadarPage extends ConsumerWidget {
  const CryptoRadarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cryptoRadarProvider);
    final notifier = ref.read(cryptoRadarProvider.notifier);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 18, 12),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: AppTheme.up(brightness),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('庄家雷达', style: theme.textTheme.headlineLarge),
                    ],
                  ),
                ),
                if (state.status == ScanStatus.scanning)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _IconBtn(
                    icon: Icons.refresh_rounded,
                    onTap: () => notifier.startFullScan(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, ref, theme, brightness, state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Brightness brightness,
    CryptoRadarState state,
  ) {
    switch (state.status) {
      case ScanStatus.idle:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar_rounded, size: 64,
                    color: AppTheme.tint(brightness)),
                const SizedBox(height: 16),
                Text('点击右上角刷新开始扫描',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.read(cryptoRadarProvider.notifier).startFullScan(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('开始扫描'),
                ),
              ],
            ),
          ),
        );
      case ScanStatus.scanning:
        return const Center(child: CircularProgressIndicator());
      case ScanStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48,
                    color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('扫描失败', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(state.error ?? '未知错误',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.read(cryptoRadarProvider.notifier).startFullScan(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      case ScanStatus.done:
        return RefreshIndicator(
          onRefresh: () => ref.read(cryptoRadarProvider.notifier).startFullScan(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildMarketOverview(context, theme, brightness, state),
              if (state.highlights.isNotEmpty)
                _HighlightsSection(highlights: state.highlights),
              if (state.chaseSignals.isNotEmpty)
                _SignalSection(title: '追多（费率极端）', signals: state.chaseSignals, brightness: brightness),
              if (state.ambushSignals.isNotEmpty)
                _SignalSection(title: '埋伏（低市值 + OI）', signals: state.ambushSignals, brightness: brightness),
              if (state.combinedSignals.isNotEmpty)
                _SignalSection(title: '综合（四维评分）', signals: state.combinedSignals, brightness: brightness),
              if (state.heatList.isNotEmpty)
                _HeatSection(heatList: state.heatList, brightness: brightness),
            ],
          ),
        );
    }
  }

  Widget _buildMarketOverview(
    BuildContext context,
    ThemeData theme,
    Brightness brightness,
    CryptoRadarState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.hair(brightness)),
          boxShadow: AppTheme.cardShadow(brightness),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('市场概览 · 实时',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                    )),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _OvCell(
                  value: '${state.chaseSignals.length}',
                  label: '追多信号',
                  color: AppTheme.warn(brightness),
                ),
                const SizedBox(width: 8),
                _OvCell(
                  value: '${state.ambushSignals.length}',
                  label: '埋伏信号',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _OvCell(
                  value: '${state.combinedSignals.length}',
                  label: '综合信号',
                  color: AppTheme.up(brightness),
                ),
                const SizedBox(width: 8),
                _OvCell(
                  value: '${state.heatList.length}',
                  label: '热度榜',
                  color: AppTheme.down(brightness),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OvCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _OvCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface2(theme.brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightsSection extends StatelessWidget {
  final List<String> highlights;
  const _HighlightsSection({required this.highlights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final h in highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $h', style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

class _SignalSection extends StatelessWidget {
  final String title;
  final List<dynamic> signals;
  final Brightness brightness;
  const _SignalSection({
    required this.title,
    required this.signals,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = title.contains('追多')
        ? AppTheme.warn(brightness)
        : title.contains('埋伏')
            ? theme.colorScheme.primary
            : AppTheme.up(brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded,
                    size: 15, color: iconColor),
                const SizedBox(width: 6),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                )),
                const SizedBox(width: 6),
                Text('${signals.length} 个',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          ...signals.map((s) => _SignalCard(signal: s)),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final dynamic signal;
  const _SignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ts = signal as dynamic;
    final coin = ts.coin as String;
    final direction = ts.direction as String;
    final score = ts.score as int;
    final strategy = ts.strategy as String;
    final tags = (ts.tags as List).cast<String>();
    final isUp = score >= 65;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface2(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hair(brightness)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUp
                  ? AppTheme.up(brightness).withValues(alpha: 0.14)
                  : AppTheme.warn(brightness).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                coin.length > 4 ? coin.substring(0, 4) : coin,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isUp ? AppTheme.up(brightness) : AppTheme.warn(brightness),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(coin,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(direction,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w400,
                        )),
                    const Spacer(),
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isUp ? AppTheme.up(brightness) : AppTheme.warn(brightness),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(strategy,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    )),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    children: tags.map((t) => _SigTag(
                      text: t,
                      isUp: t.contains('OI') || t.contains('强趋势'),
                      brightness: brightness,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SigTag extends StatelessWidget {
  final String text;
  final bool isUp;
  final Brightness brightness;
  const _SigTag({
    required this.text,
    required this.isUp,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUp ? AppTheme.up(brightness) : theme.colorScheme.primary;
    final bg = isUp
        ? AppTheme.up(brightness).withValues(alpha: 0.13)
        : AppTheme.tint(brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _HeatSection extends StatelessWidget {
  final List<CoinData> heatList;
  final Brightness brightness;
  const _HeatSection({
    required this.heatList,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 15, color: AppTheme.down(brightness)),
                const SizedBox(width: 6),
                Text('热度',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                    )),
                const SizedBox(width: 6),
                Text('${heatList.length} 个币',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          for (final d in heatList)
            _HeatRow(data: d, brightness: brightness),
        ],
      ),
    );
  }
}

class _HeatRow extends StatelessWidget {
  final CoinData data;
  final Brightness brightness;
  const _HeatRow({
    required this.data,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = data.pxChg >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surface2(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hair(brightness)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.down(brightness).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                data.coin.length > 3 ? data.coin.substring(0, 3) : data.coin,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.down(brightness),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.coin,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text('热度 ${data.heat.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    )),
              ],
            ),
          ),
          Text(
            '${isUp ? '+' : ''}${data.pxChg.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isUp ? AppTheme.up(brightness) : AppTheme.down(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}
