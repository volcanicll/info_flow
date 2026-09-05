import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/state/fomo_api_key_store.dart';
import '../../../../core/state/library_store.dart';
import '../../../../core/storage/kv_storage.dart';
import '../../../feed/data/rss_sources.dart';
import '../widgets/profile_sections.dart';

/// 个人中心：专注链上终端配置、自选池管理、GoPlus 安全设置与多链偏好。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final library = ref.watch(libraryStoreProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Masthead
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TERMINAL · 链上终端',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: c.accent)),
                  const SizedBox(height: 2),
                  Text('终端设置', style: theme.textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text('专注 Robinhood · BSC · Base · SOL 链上生态',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: c.inkTertiary)),
                ],
              ),
            ),
            // On-chain Stats
            ProfileStats(items: [
              (value: '${library.bookmarkCount}', label: '自选/收藏'),
              (value: '4', label: '核心链生态'),
              (value: 'GoPlus', label: '安全审计引擎'),
            ]),
            const SizedBox(height: 8),
            // 功能专区
            ProfileSection(
              kicker: 'CHAIN TOOLS · 链上工具',
              title: '链上工具',
              children: [
                ProfileRow(
                  title: '我的自选 / 收藏池',
                  subtitle: '已收藏的链上情报与标的',
                  onTap: () => context.push('/bookmark'),
                ),
                ProfileRow(
                  title: '代币探测与安全审计',
                  subtitle: '全链合约检索与貔貅检测',
                  onTap: () => context.push('/token-screener'),
                ),
                ProfileRow(
                  title: '加密与异动雷达',
                  subtitle: '大额异动与持仓扫描',
                  onTap: () => context.push('/crypto-radar'),
                ),
                ProfileRow(
                  title: 'Web3 情报源管理',
                  subtitle: '已聚合 ${RssSources.all.length} 个专业链上情报源',
                  onTap: () => context.push('/subscription'),
                ),
                ProfileRow(
                  title: '链上异动提醒',
                  subtitle: '捕获新异动或巨鲸信号时推送',
                  trailing: Switch(
                    value: ref.watch(signalNotifyPrefProvider),
                    onChanged: (v) => ref
                        .read(signalNotifyPrefProvider.notifier)
                        .setEnabled(v),
                  ),
                ),
                ProfileRow(
                  title: '基准市场总览',
                  subtitle: 'BTC · ETH · SOL · BNB 现货行情',
                  onTap: () => context.push('/market-overview'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 外观设置
            ProfileSection(
              kicker: 'APPEARANCE · 外观',
              title: '外观与偏好',
              children: [
                ProfileRow(
                  title: '深色模式',
                  trailing: _ThemeSeg(themeMode: themeMode),
                ),
                ProfileRow(
                  title: '字号调节',
                  value: _fontSizeLabel(fontSize),
                  onTap: () => _showFontSizeSheet(context, ref, fontSize),
                ),
                ProfileRow(
                  title: '语言',
                  value: '简体中文',
                  onTap: () => _showLanguageSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 聪明钱数据源（fomoapi.io 免费档）
            ProfileSection(
              kicker: 'DATA · 数据源',
              title: '聪明钱数据源',
              children: [
                ProfileRow(
                  title: 'FOMO API Key',
                  subtitle: 'fomoapi.io 免费档，解锁代币聪明钱持仓与更多窗口榜单',
                  value: ref.watch(fomoApiKeyStoreProvider).trim().isEmpty
                      ? '未配置'
                      : '已配置',
                  onTap: () => _showFomoKeySheet(
                      context, ref, ref.read(fomoApiKeyStoreProvider)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 关于与协议
            ProfileSection(
              kicker: 'ABOUT · 关于',
              title: '关于平台',
              children: [
                const ProfileRow(
                  title: '链上数据源',
                  value: 'DexScreener + GoPlus',
                ),
                ProfileRow(
                  title: '关于 InfoFlow Terminal',
                  value: 'v2.0.0 (On-Chain)',
                  onTap: () => _showAboutDialog(context),
                ),
                ProfileRow(
                  title: '推荐给交易员朋友',
                  onTap: () => Share.share(
                    '推荐使用 InfoFlow 生产级链上信息平台，专注于 Robinhood, BSC, Base, SOL 链上生态！',
                    subject: 'InfoFlow Terminal',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fontSizeLabel(double size) {
    if (size <= 13) return '小';
    if (size <= 16) return '中 · 16pt';
    if (size <= 19) return '大';
    return '特大';
  }

  /// FOMO API Key 配置弹层：免费 key 到 fomoapi.io/dashboard 注册获取。
  void _showFomoKeySheet(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FOMO API Key',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              '配置后解锁：代币聪明钱持仓（谁在持、持仓量）。'
              '免费档 10,000 请求/月，到 fomoapi.io/dashboard 免费注册；'
              '不配置时多窗口收益榜仍可用（免 key）。',
              style: Theme.of(ctx)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: ctx.colors.inkTertiary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                isDense: true,
                hintText: '粘贴 API Key',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref
                      .read(fomoApiKeyStoreProvider.notifier)
                      .setKey(ctrl.text);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FOMO API Key 已保存')),
                  );
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final languages = [
      ('简体中文', 'zh_CN'),
      ('English', 'en'),
    ];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择语言', style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ...languages.map((lang) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(lang.$1),
                  trailing: lang.$2 == 'zh_CN'
                      ? Icon(Icons.check_rounded, color: ctx.colors.accent)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (lang.$2 != 'zh_CN') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${lang.$1}语言包即将上线')),
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('关于 InfoFlow Terminal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: v2.0.0 (生产级链上版)',
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              '专注于 Robinhood、BSC、Base、SOL 四大区块链生态。'
              '聚合 DexScreener 流动性行情、GoPlus 智能合约貔貅审计、巨鲸聪明钱异动与全天候链上情报。',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeSheet(BuildContext context, WidgetRef ref, double current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        double value = current;
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('正文字号', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('${value.round()} pt',
                      style: AppTheme.mono(theme.textTheme.titleLarge!
                          .copyWith(color: context.colors.accent))),
                  Slider(
                    value: value,
                    min: 12,
                    max: 24,
                    divisions: 6,
                    label: '${value.round()}',
                    onChanged: (v) => setState(() => value = v),
                    onChangeEnd: (v) =>
                        ref.read(fontSizeProvider.notifier).setFontSize(v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '示例：这是情报与代币研报的字号预览效果。',
                    style: TextStyle(fontSize: value),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ThemeSeg extends ConsumerWidget {
  final ThemeMode themeMode;
  const _ThemeSeg({required this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final options = [
      ('跟随', ThemeMode.system),
      ('浅色', ThemeMode.light),
      ('深色', ThemeMode.dark),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final active = themeMode == opt.$2;
        return GestureDetector(
          onTap: () =>
              ref.read(themeModeProvider.notifier).setThemeMode(opt.$2),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  opt.$1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: active ? c.ink : c.inkTertiary,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 16,
                  height: 2,
                  color: active ? c.accent : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
