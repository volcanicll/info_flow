import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/models/metal_price.dart';
import '../controllers/metals_controller.dart';

/// 贵金属行情（财经报纸表格化）：等宽报价 + 涨跌文字色，发丝线分隔。
class MetalsPage extends ConsumerWidget {
  const MetalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metalsProvider);
    final notifier = ref.read(metalsProvider.notifier);
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
                        Text('METALS · 实时报价',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: c.accent)),
                        const SizedBox(height: 2),
                        Text('贵金属', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                  if (state.status == MetalsStatus.loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconBtn(
                        icon: Icons.refresh_rounded,
                        onTap: () => notifier.loadPrices()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            Expanded(child: _body(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MetalsState state, Metals notifier) {
    switch (state.status) {
      case MetalsStatus.idle:
        return _MetalsMessage(
          icon: Icons.monetization_on_outlined,
          title: '行情待命',
          subtitle: '获取纽约金银与上海金银实时报价',
          actionLabel: '加载行情',
          onAction: notifier.loadPrices,
        );
      case MetalsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case MetalsStatus.error:
        return _MetalsMessage(
          icon: Icons.error_outline_rounded,
          title: '加载失败',
          subtitle: state.error ?? '未知错误',
          actionLabel: '重试',
          onAction: notifier.loadPrices,
        );
      case MetalsStatus.done:
        if (state.prices.isEmpty) {
          return _MetalsMessage(
            icon: Icons.inbox_outlined,
            title: '暂无数据',
            actionLabel: '刷新',
            onAction: notifier.loadPrices,
          );
        }
        return RefreshIndicator(
          onRefresh: () => notifier.loadPrices(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SectionHeader(kicker: '新浪财经 · 延迟约 15 秒', title: '实时报价'),
              for (var i = 0; i < state.prices.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Hairline(),
                  ),
                _MetalRow(metal: state.prices[i]),
              ],
            ],
          ),
        );
    }
  }
}

/// 报价行：币种 + 计价货币 | 等宽价格 + 涨跌（趋势色文字，无色块）。
class _MetalRow extends StatelessWidget {
  final MetalPrice metal;
  const _MetalRow({required this.metal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final trend = metal.isUp ? c.up : c.down;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metal.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('${metal.code} · ${metal.currency}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: c.inkTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(metal.priceFormatted,
                  style: AppTheme.mono(theme.textTheme.headlineMedium!)),
              const SizedBox(height: 2),
              Text(metal.changeFormatted,
                  style: AppTheme.mono(theme.textTheme.labelMedium!
                      .copyWith(color: trend, fontWeight: FontWeight.w700))),
            ],
          ),
        ],
      ),
    );
  }
}

/// 空闲 / 错误 / 空数据态。
class _MetalsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  const _MetalsMessage({
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
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
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
