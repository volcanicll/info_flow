import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/crypto_repository.dart';
import '../controllers/crypto_radar_controller.dart';

class CryptoRadarPage extends ConsumerWidget {
  const CryptoRadarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cryptoRadarProvider);
    final notifier = ref.read(cryptoRadarProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏦 庄家雷达'),
        actions: [
          if (state.status == ScanStatus.scanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => notifier.startFullScan(),
            ),
        ],
      ),
      body: _buildBody(context, ref, theme, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ThemeData theme, CryptoRadarState state) {
    switch (state.status) {
      case ScanStatus.idle:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('点击刷新开始扫描', style: theme.textTheme.titleMedium),
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
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 24),
            Center(
              child: Text(
                state.progressMessage.isNotEmpty ? state.progressMessage : '正在扫描永续合约市场…',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          ],
        );
      case ScanStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('扫描失败', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(state.error ?? '未知错误', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
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
              _buildMarketOverview(context, theme, state),
              if (state.highlights.isNotEmpty) _HighlightsSection(highlights: state.highlights),
              if (state.chaseSignals.isNotEmpty) _SignalSection(title: '🚀 追多（费率极端）', signals: state.chaseSignals),
              if (state.ambushSignals.isNotEmpty) _SignalSection(title: '🎯 埋伏（低市值+OI）', signals: state.ambushSignals),
              if (state.combinedSignals.isNotEmpty) _SignalSection(title: '📊 综合（四维评分）', signals: state.combinedSignals),
              if (state.heatList.isNotEmpty) _HeatSection(heatList: state.heatList),
            ],
          ),
        );
    }
  }

  Widget _buildMarketOverview(BuildContext context, ThemeData theme, CryptoRadarState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5B5BD6).withValues(alpha: 0.1),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('市场概览', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewChip(
                label: '追多信号',
                value: '${state.chaseSignals.length}',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _OverviewChip(
                label: '埋伏信号',
                value: '${state.ambushSignals.length}',
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              _OverviewChip(
                label: '综合信号',
                value: '${state.combinedSignals.length}',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _OverviewChip(
                label: '热度',
                value: '${state.heatList.length}',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final String label, value;
  final Color color;

  const _OverviewChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💡 重点关注', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final h in highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(h, style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignalSection extends StatelessWidget {
  final String title;
  final List<dynamic> signals;
  const _SignalSection({required this.title, required this.signals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
    final ts = signal as dynamic;
    final coin = ts.coin as String;
    final direction = ts.direction as String;
    final score = ts.score as int;
    final strategy = ts.strategy as String;
    final tags = (ts.tags as List).cast<String>();
    final urgency = ts.urgency as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: score >= 70
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                coin.length > 4 ? coin.substring(0, 4) : coin,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: score >= 70 ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(coin, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(direction, style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text('$score分', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: score >= 70 ? Colors.green : Colors.orange,
                    )),
                    const SizedBox(width: 4),
                    Text(urgency, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(strategy, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(t, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                    )).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatSection extends StatelessWidget {
  final List<CoinData> heatList;
  const _HeatSection({required this.heatList});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('🔥 热度', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text('${heatList.length}个币', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          for (final d in heatList)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        d.coin.length > 3 ? d.coin.substring(0, 3) : d.coin,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.coin, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('热度${d.heat.toStringAsFixed(0)}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                  Text('${d.pxChg >= 0 ? '+' : ''}${d.pxChg.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: d.pxChg >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
