import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref.read(tokenScreenerProvider.notifier).search(val);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tokenScreenerProvider);
    final theme = Theme.of(context);
    final c = context.colors;

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
            // 结果列表
            Expanded(
              child: state.loading && state.results.isEmpty
                  ? Center(
                      child: Text(
                        '正在探测链上代币…',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: c.inkTertiary),
                      ),
                    )
                  : state.error != null && state.results.isEmpty
                      ? EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: '探测失败',
                          description: state.error!,
                          actionLabel: '重试',
                          actionIcon: Icons.refresh_rounded,
                          onAction: () => ref
                              .read(tokenScreenerProvider.notifier)
                              .loadTrending(
                                  state.selectedChain ?? ChainType.solana),
                        )
                      : state.results.isEmpty
                          ? const EmptyState(
                              icon: Icons.radar_rounded,
                              title: '未检索到代币',
                              description: '请核对合约地址 (CA) 或尝试直接搜索代币名称',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 32),
                              itemCount: state.results.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final token = state.results[index];
                                return TokenCard(token: token);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

