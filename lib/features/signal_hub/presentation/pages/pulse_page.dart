import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            SliverToBoxAdapter(child: _buildHeader(theme)),
            if (state.articles.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('暂无资讯，下拉刷新或稍后再看'),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: state.articles.length,
                itemBuilder: (context, i) {
                  final a = state.articles[i];
                  return Column(
                    children: [
                      ArticleCard(
                        article: a,
                        onTap: () {}, // Task 8 接路由跳转 Reader
                      ),
                      if (a.tickers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: a.tickers.map((t) {
                              // quotes 是 Map<String, dynamic>，需做类型检查
                              final q = state.quotes[t.symbol];
                              return TickerBadge(
                                ref: t,
                                quote: q is TickerQuote ? q : null,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text('脉搏 Pulse', style: theme.textTheme.headlineLarge),
          const Spacer(),
          Icon(Icons.graphic_eq_rounded,
              size: 20, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}
