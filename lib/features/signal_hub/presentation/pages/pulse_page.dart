import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/animated_entrance.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../feed/presentation/widgets/article_row.dart';
import '../../domain/entities/ticker_quote.dart';
import '../../../market/presentation/widgets/fear_greed_strip.dart';
import '../controllers/pulse_controller.dart';
import '../widgets/ticker_badge.dart';

/// 脉搏首页（财经报纸风）：按发布时间倒序的资讯流，每条文章下方追加命中的
/// [TickerBadge] 行情条，条目间以发丝线分隔。
class PulsePage extends ConsumerWidget {
  const PulsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pulseControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(pulseControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            // 空态时仍可下拉触发刷新（参照 feed_page.dart 的做法）
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Masthead(theme: theme)),
              const SliverToBoxAdapter(child: FearGreedStrip()),
              if (state.articles.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyPulse(theme: theme),
                )
              else
                SliverList.separated(
                  itemCount: state.articles.length,
                  separatorBuilder: (_, _) => const Hairline(),
                  itemBuilder: (context, i) {
                    final a = state.articles[i];
                    return AnimatedEntrance(
                      index: i,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ArticleRow(
                            article: a,
                            onTap: () => context.push('/reader/${a.id}'),
                          ),
                          if (a.tickers.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 14),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: a.tickers.map((t) {
                                  final q = state.quotes[t.symbol];
                                  return TickerBadge(
                                    ref: t,
                                    quote: q is TickerQuote ? q : null,
                                    onTap: () => context.push('/crypto-radar'),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 报头：全大写 kicker + 衬线大标题 + 右侧检索入口，下缀重发丝线。
class _Masthead extends StatelessWidget {
  final ThemeData theme;
  const _Masthead({required this.theme});

  @override
  Widget build(BuildContext context) {
    final brightness = theme.brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PULSE · 实时脉搏',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.down(brightness),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('脉搏', style: theme.textTheme.displayMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search_rounded, size: 22),
                tooltip: '检索',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Hairline(color: AppTheme.hairStrong(brightness)),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// 空态：报纸留白式文案，包含「稍后」以引导重访。
class _EmptyPulse extends StatelessWidget {
  final ThemeData theme;
  const _EmptyPulse({required this.theme});

  @override
  Widget build(BuildContext context) {
    final brightness = theme.brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded,
                size: 44, color: AppTheme.hairStrong(brightness)),
            const SizedBox(height: 16),
            Text('暂无脉搏', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '下拉刷新，或稍后再来查看最新资讯',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/subscription'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('添加订阅源'),
            ),
          ],
        ),
      ),
    );
  }
}
