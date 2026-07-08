import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/animated_entrance.dart';
import '../../../feed/presentation/widgets/article_card.dart';
import '../../domain/entities/ticker_quote.dart';
import '../controllers/pulse_controller.dart';
import '../widgets/ticker_badge.dart';

/// 脉搏首页：展示按发布时间倒序的资讯流，每条文章下方追加命中的 TickerBadge。
class PulsePage extends ConsumerWidget {
  const PulsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pulseControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(pulseControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          // 空态时仍可下拉触发刷新（参照 feed_page.dart 的做法）
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, theme)),
            if (state.articles.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.graphic_eq_rounded, size: 48,
                            color: AppTheme.hairStrong(theme.brightness)),
                        const SizedBox(height: 16),
                        Text('暂无资讯', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('下拉刷新或添加订阅源',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => context.push('/feed/subscription'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('添加订阅源'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: state.articles.length,
                itemBuilder: (context, i) {
                  final a = state.articles[i];
                  return AnimatedEntrance(
                    index: i,
                    child: Column(
                      children: [
                        ArticleCard(
                          article: a,
                          onTap: () => context.push('/reader/${a.id}'),
                        ),
                        if (a.tickers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final brightness = theme.brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: AppTheme.down(brightness),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text('脉搏 Pulse', style: theme.textTheme.headlineLarge),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 40, height: 40,
                child: Icon(Icons.search_rounded, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
