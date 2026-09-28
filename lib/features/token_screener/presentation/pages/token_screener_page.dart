import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/load_more_footer.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../domain/models/onchain_token.dart';
import '../controllers/token_screener_controller.dart';
import '../widgets/token_screener_widgets.dart';

class TokenScreenerPage extends ConsumerStatefulWidget {
  const TokenScreenerPage({super.key});

  @override
  ConsumerState<TokenScreenerPage> createState() => _TokenScreenerPageState();
}

class _TokenScreenerPageState extends ConsumerState<TokenScreenerPage> {
  final _searchController = TextEditingController();
  final _listController = ScrollController();

  /// 本地触底分页：结果集为一次性拉取，按窗口渐进渲染。
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;
  List<OnChainToken>? _lastResults;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    // 输入内容变化时刷新清除按钮的显隐（suffixIcon 依赖 text.isNotEmpty）
    _searchController.addListener(_onSearchChanged);
    _listController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_listController.position.extentAfter < 200) _loadMore();
  }

  Future<void> _loadMore() async {
    final total = ref.read(tokenScreenerProvider).results.length;
    if (_loadingMore || _visibleCount >= total) return;
    setState(() => _loadingMore = true);
    // 短暂停顿让页脚 spinner 有感知（本地数据无网络延迟）
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _visibleCount += _pageSize;
      _loadingMore = false;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _listController.removeListener(_onScroll);
    _listController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(tokenScreenerProvider.notifier).search(val);
  }

  /// 下拉刷新：有查询词重搜，否则按当前链生态重拉热榜。
  Future<void> _reload() async {
    HapticFeedback.selectionClick();
    final notifier = ref.read(tokenScreenerProvider.notifier);
    final cur = ref.read(tokenScreenerProvider);
    if (cur.query.isNotEmpty) {
      await notifier.search(cur.query);
    } else {
      await notifier.loadTrending(cur.selectedChain ?? ChainType.solana);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tokenScreenerProvider);
    final theme = Theme.of(context);
    final c = context.colors;

    // 结果集实例变化（新搜索/切链）时重置分页窗口
    if (!identical(state.results, _lastResults)) {
      _lastResults = state.results;
      _visibleCount = _pageSize;
    }
    final visibleResults = state.results.take(_visibleCount).toList(growable: false);
    final hasMore = _visibleCount < state.results.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCREENER · 链上代币探测',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('代币探测与安全', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                  if (state.loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconBtn(
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        if (state.query.isNotEmpty) {
                          _onSearch(state.query);
                        } else if (state.selectedChain != null) {
                          ref
                              .read(tokenScreenerProvider.notifier)
                              .loadTrending(state.selectedChain!);
                        }
                      },
                    ),
                ],
              ),
            ),
            // 搜索输入框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: c.hairlineStrong, width: 0.8),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '输入合约地址 (CA) 或 代币 Symbol...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: c.inkTertiary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            // 链生态筛选 Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChainPill(
                      label: 'Solana',
                      chain: ChainType.solana,
                      active: state.selectedChain == ChainType.solana,
                      color: ChainColors.solana,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.solana);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChainPill(
                      label: 'Base',
                      chain: ChainType.base,
                      active: state.selectedChain == ChainType.base,
                      color: ChainColors.base,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.base);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChainPill(
                      label: 'BSC',
                      chain: ChainType.bsc,
                      active: state.selectedChain == ChainType.bsc,
                      color: ChainColors.bsc,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.bsc);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChainPill(
                      label: 'Robinhood',
                      chain: ChainType.robinhood,
                      active: state.selectedChain == ChainType.robinhood,
                      color: ChainColors.robinhood,
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(tokenScreenerProvider.notifier)
                            .loadTrending(ChainType.robinhood);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            // 结果列表：支持下拉刷新（错误/空态也保持可下拉）
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                color: c.accent,
                child: state.loading && state.results.isEmpty
                    ? const _ScreenerSkeleton()
                    : state.error != null && state.results.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 120),
                            children: [
                              EmptyState(
                                icon: Icons.error_outline_rounded,
                                title: '探测失败',
                                description: state.error!,
                                actionLabel: '重试',
                                actionIcon: Icons.refresh_rounded,
                                onAction: () => ref
                                    .read(tokenScreenerProvider.notifier)
                                    .loadTrending(
                                        state.selectedChain ??
                                            ChainType.solana),
                              ),
                            ],
                          )
                        : state.results.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(top: 120),
                                children: const [
                                  EmptyState(
                                    icon: Icons.radar_rounded,
                                    title: '未检索到代币',
                                    description:
                                        '请核对合约地址 (CA) 或尝试直接搜索代币名称',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: _listController,
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 32),
                                itemCount: visibleResults.length + 1,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  if (index == visibleResults.length) {
                                    return LoadMoreFooter(
                                      hasMore: hasMore,
                                      loadingMore: _loadingMore,
                                    );
                                  }
                                  return TokenCard(
                                      token: visibleResults[index]);
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 探测结果卡骨架：模拟 TokenCard 的排版结构（徽章行 + 统计行）。
class _ScreenerSkeleton extends StatelessWidget {
  const _ScreenerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.colors.hairlineStrong, width: 0.6),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 44, height: 16),
                SizedBox(width: 8),
                SkeletonBox(width: 90, height: 15),
                Spacer(),
                SkeletonBox(width: 64, height: 15),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 56, height: 24),
                SkeletonBox(width: 64, height: 24),
                SkeletonBox(width: 72, height: 24),
                SkeletonBox(width: 60, height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

