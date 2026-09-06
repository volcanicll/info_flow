import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../smart_money/presentation/widgets/token_holders_section.dart';
import '../../../token_screener/domain/models/onchain_token.dart';
import '../controllers/coin_detail_controller.dart';
import '../widgets/coin_detail_widgets.dart';

/// 币种/代币详情：实时报价 + 链上安全体检 (GoPlus) + 流动性指标 + 迷你K线。
class CoinDetailPage extends ConsumerStatefulWidget {
  final String symbol;
  final String? address;
  final String? chain;

  const CoinDetailPage({
    super.key,
    required this.symbol,
    this.address,
    this.chain,
  });

  @override
  ConsumerState<CoinDetailPage> createState() => _CoinDetailPageState();
}

class _CoinDetailPageState extends ConsumerState<CoinDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coinDetailProvider(widget.symbol).notifier).load(
            address: widget.address,
            chainId: widget.chain,
          );
    });
  }

  void _copyAddress(String addr) {
    Clipboard.setData(ClipboardData(text: addr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 合约地址已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openExplorer(String addr, ChainType chain) async {
    String url = '';
    switch (chain) {
      case ChainType.solana:
        url = 'https://solscan.io/token/$addr';
      case ChainType.base:
        url = 'https://basescan.org/token/$addr';
      case ChainType.bsc:
        url = 'https://bscscan.com/token/$addr';
      case ChainType.robinhood:
        url = 'https://dexscreener.com/search?q=$addr';
    }

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coinDetailProvider(widget.symbol));
    final notifier = ref.read(coinDetailProvider(widget.symbol).notifier);
    final theme = Theme.of(context);
    final c = context.colors;

    ref.listen(coinDetailProvider(widget.symbol), (prev, next) {
      if (prev?.error == null && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

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
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOKEN PROFILE · 链上代币详情',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(widget.symbol, style: theme.textTheme.displayMedium),
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
                      onTap: () => notifier.load(
                        address: widget.address,
                        chainId: widget.chain,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            Expanded(child: _body(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CoinDetailState state) {
    final theme = Theme.of(context);
    final c = context.colors;

    if (state.price == null && !state.loading && state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error ?? '加载数据失败', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref
                  .read(coinDetailProvider(widget.symbol).notifier)
                  .load(address: widget.address, chainId: widget.chain),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final price = state.price;
    final change = state.changePercent ?? 0;
    final isUp = change >= 0;
    final oct = state.onchainToken;
    final sec = state.security;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // 报价头部
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (price != null)
                          Text(
                            _formatPrice(price),
                            style: AppTheme.mono(
                              theme.textTheme.displayLarge!.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isUp ? c.up : c.down,
                              ),
                            ),
                          )
                        else
                          Text('--', style: theme.textTheme.displayLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%  ·  '
                          '24h 成交 ${_formatVol(state.volume)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: c.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (oct != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getChainColor(oct.chain).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getChainColor(oct.chain),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        oct.chain.shortName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _getChainColor(oct.chain),
                        ),
                      ),
                    ),
                ],
              ),
              // 合约快捷复制
              if (oct != null && oct.address.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _copyAddress(oct.address),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.grey.shade100
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _shortenAddress(oct.address),
                          style: AppTheme.mono(
                            TextStyle(fontSize: 11, color: c.inkSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '点击复制',
                          style: TextStyle(fontSize: 10, color: c.accent),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openExplorer(oct.address, oct.chain),
                          child: Row(
                            children: [
                              Text(
                                '区块浏览器',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: c.inkTertiary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 12,
                                color: c.inkTertiary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // GoPlus 链上安全审计卡片
        if (sec != null) ...[
          const SectionHeader(kicker: 'GOPLUS · SECURITY AUDIT', title: '链上安全审计'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SecurityCard(security: sec),
          ),
        ],

        // 聪明钱持仓（需在设置中配置 FOMO API Key，未配置自动隐藏）
        TokenHoldersSection(address: widget.address),

        // 链上池子与流动性指标
        if (oct != null) ...[
          const SectionHeader(kicker: 'LIQUIDITY · DEX POOL', title: '流动性与交易指标'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: c.hairlineStrong, width: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MetricItem(label: '流动性池', value: _formatVol(oct.liquidityUsd)),
                  MetricItem(label: 'FDV 总市值', value: _formatVol(oct.fdv)),
                  MetricItem(label: '24h 买单', value: '${oct.txns24hBuys} 笔'),
                  MetricItem(label: '24h 卖单', value: '${oct.txns24hSells} 笔'),
                ],
              ),
            ),
          ),
        ],

        // 迷你 K 线
        if (state.closes.length >= 2) ...[
          const SectionHeader(kicker: '48H · CLOSE', title: '价格走势折线'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SizedBox(
              height: 120,
              child: SparklineChart(values: state.closes, up: isUp),
            ),
          ),
        ],

        // 资金费率（若是合约支持币种）
        if (state.fundingRates.isNotEmpty) ...[
          const SectionHeader(kicker: 'FUNDING · 最近 12 期', title: '资金费率'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: BarChartWidget(
              values: state.fundingRates,
              format: (v) => '${(v * 100).toStringAsFixed(3)}%',
              positiveColor: c.up,
              negativeColor: c.down,
            ),
          ),
        ],
      ],
    );
  }

  Color _getChainColor(ChainType chain) {
    switch (chain) {
      case ChainType.solana:
        return ChainColors.solana;
      case ChainType.base:
        return ChainColors.base;
      case ChainType.bsc:
        return ChainColors.bsc;
      case ChainType.robinhood:
        return ChainColors.robinhood;
    }
  }

  String _shortenAddress(String addr) {
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  String _formatPrice(double v) {
    if (v >= 1000) return '\$${v.toStringAsFixed(2)}';
    if (v >= 1) return '\$${v.toStringAsFixed(4)}';
    if (v >= 0.0001) return '\$${v.toStringAsFixed(6)}';
    return '\$${v.toStringAsFixed(8)}';
  }

  String _formatVol(double? v) {
    if (v == null || v <= 0) return '--';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}
