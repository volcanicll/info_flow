import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/fomo_api_key_store.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/datasources/fomo_api.dart';
import '../format.dart';

/// 代币详情页的「聪明钱持仓」区块：哪些被追踪大户正持有该代币。
///
/// 未配置 FOMO API Key 或无合约地址时整体隐藏，不打扰默认视图；
/// fomoapi.io 免费档 key 在 设置 → 聪明钱数据源 中配置。
class TokenHoldersSection extends ConsumerWidget {
  final String? address;

  const TokenHoldersSection({super.key, required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keySet = ref.watch(fomoApiKeyStoreProvider).trim().isNotEmpty;
    final addr = address;
    if (!keySet || addr == null || addr.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final c = context.colors;
    final async = ref.watch(tokenHoldersProvider(addr));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          kicker: 'SMART MONEY · HOLDERS',
          title: '聪明钱持仓',
        ),
        async.when(
          data: (holders) {
            if (holders.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text('暂无被追踪大户持有该代币',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: c.inkTertiary)),
              );
            }
            final sorted = [...holders]..sort((a, b) => b.valueUsd.compareTo(a.valueUsd));
            return Column(
              children: [
                for (final (i, h) in sorted.take(8).indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Hairline(color: c.hairline),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(h.handle,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Text('${amount(h.amount)}枚',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: c.inkTertiary)),
                        const SizedBox(width: 10),
                        Text(usd(h.valueUsd),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          error: (_, _) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('持仓数据暂不可用',
                style:
                    theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary)),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
