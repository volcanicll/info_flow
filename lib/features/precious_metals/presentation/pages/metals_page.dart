import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../domain/models/metal_price.dart';
import '../controllers/metals_controller.dart';

class MetalsPage extends ConsumerWidget {
  const MetalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metalsProvider);
    final notifier = ref.read(metalsProvider.notifier);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 18, 12),
            child: Row(
              children: [
                IconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on_outlined,
                          size: 20, color: _goldColor),
                      const SizedBox(width: 8),
                      Text('贵金属行情',
                          style: theme.textTheme.headlineLarge),
                    ],
                  ),
                ),
                if (state.status == MetalsStatus.loading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconBtn(
                    icon: Icons.refresh_rounded,
                    onTap: () => notifier.loadPrices(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, theme, brightness, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    Brightness brightness,
    MetalsState state,
    MetalsNotifier notifier,
  ) {
    switch (state.status) {
      case MetalsStatus.idle:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on, size: 64,
                    color: _goldColor.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                Text('点击刷新获取实时贵金属行情',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => notifier.loadPrices(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('加载行情'),
                ),
              ],
            ),
          ),
        );
      case MetalsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case MetalsStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48,
                    color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('加载失败', style: theme.textTheme.titleMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => notifier.loadPrices(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      case MetalsStatus.done:
        if (state.prices.isEmpty) {
          return Center(
            child: Text('暂无数据', style: theme.textTheme.titleMedium),
          );
        }
        return RefreshIndicator(
          onRefresh: () => notifier.loadPrices(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
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
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: _goldColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('实时报价 · 新浪财经',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('数据延迟约 15 秒',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          )),
                    ],
                  ),
                ),
              ),
              ...state.prices.map((p) => _MetalCard(
                metal: p, brightness: brightness, theme: theme,
              )),
            ],
          ),
        );
    }
  }
}

const _goldColor = Color(0xFFD4A843);

class _MetalCard extends StatelessWidget {
  final MetalPrice metal;
  final Brightness brightness;
  final ThemeData theme;
  const _MetalCard({
    required this.metal,
    required this.brightness,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = metal.isUp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface2(brightness),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.hair(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _goldColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child:               Icon(
                metal.code == 'XAU' || metal.code == 'AUTD'
                    ? Icons.circle_rounded
                    : Icons.square_rounded,
                size: 24, color: _goldColor,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(metal.currency,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      )),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                  Text(
                    '\$${metal.priceFormatted}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isUp
                            ? AppTheme.up(brightness)
                            : AppTheme.down(brightness))
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    metal.changeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isUp
                          ? AppTheme.up(brightness)
                          : AppTheme.down(brightness),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


