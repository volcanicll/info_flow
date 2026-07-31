import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../core/state/reading_stats.dart';
import '../../../../core/storage/kv_storage.dart';
import '../../../feed/data/rss_sources.dart';
import '../widgets/profile_sections.dart';

/// 我的（目录页）：章节化分组 + 页码式右对齐值，杂志目录排版。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final library = ref.watch(libraryStoreProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final readSecs = ref.watch(readingStatsProvider).totalReadSeconds;

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
                  Text('PROFILE · 我的',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: c.accent)),
                  const SizedBox(height: 2),
                  Text('我的', style: theme.textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text('已订阅 ${RssSources.all.length} 个来源',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: c.inkTertiary)),
                ],
              ),
            ),
            // Reading stats
            ProfileStats(items: [
              (value: '${library.readIds.length}', label: '已读'),
              (value: _readTimeLabel(readSecs), label: '阅读时长'),
              (value: '${library.bookmarkCount}', label: '收藏'),
            ]),
            const SizedBox(height: 8),
            // 外观
            ProfileSection(
              kicker: 'APPEARANCE · 外观',
              title: '外观',
              children: [
                ProfileRow(
                  title: '深色模式',
                  trailing: _ThemeSeg(themeMode: themeMode),
                ),
                ProfileRow(
                  title: '正文字号',
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
            // 功能
            ProfileSection(
              kicker: 'FEATURES · 功能',
              title: '功能',
              children: [
                ProfileRow(
                  title: '我的收藏',
                  onTap: () => context.push('/bookmark'),
                ),
                ProfileRow(
                  title: '订阅管理',
                  onTap: () => context.push('/subscription'),
                ),
                ProfileRow(
                  title: '离线下载',
                  subtitle: '即将推出',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('离线下载功能开发中，敬请期待')),
                  ),
                ),
                ProfileRow(
                  title: '庄家雷达',
                  subtitle: '币安合约市场扫描',
                  onTap: () => context.push('/crypto-radar'),
                ),
                ProfileRow(
                  title: '贵金属行情',
                  subtitle: '金价银价实时报价',
                  onTap: () => context.push('/metals'),
                ),
                ProfileRow(
                  title: 'AI 模型排行',
                  subtitle: 'HuggingFace 趋势模型',
                  onTap: () => context.push('/ai-models'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 关于
            ProfileSection(
              kicker: 'ABOUT · 关于',
              title: '关于',
              children: [
                ProfileRow(
                  title: '关于 InfoFlow',
                  value: 'v1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
                ProfileRow(
                  title: '帮助与反馈',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('帮助文档即将上线')),
                  ),
                ),
                ProfileRow(
                  title: '推荐给朋友',
                  onTap: () => Share.share(
                    '推荐你使用 InfoFlow，一款 AI 驱动的信息聚合 App',
                    subject: 'InfoFlow',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _readTimeLabel(int secs) {
    final m = secs ~/ 60;
    return m < 60 ? '${m}m' : '${(m / 60).toStringAsFixed(1)}h';
  }

  String _fontSizeLabel(double size) {
    if (size <= 13) return '小';
    if (size <= 16) return '中 · 16pt';
    if (size <= 19) return '大';
    return '特大';
  }

  void _showLanguageSheet(BuildContext context) {
    final languages = [
      ('简体中文', 'zh_CN'),
      ('English', 'en'),
      ('日本語', 'ja'),
      ('한국어', 'ko'),
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
        title: const Text('关于 InfoFlow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: v1.0.0', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'InfoFlow 是一款 AI 驱动的信息聚合应用，'
              '帮助您高效获取和阅读感兴趣的资讯。',
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
                    '示例正文：这是阅读器中正文的字号预览效果。',
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

/// 主题切换：铅字风三选项，激活态下方短墨线。
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
