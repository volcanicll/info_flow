import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/library_store.dart';
import '../../../../core/state/reading_stats.dart';
import '../../../../core/storage/kv_storage.dart';
import '../../../feed/data/rss_sources.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final library = ref.watch(libraryStoreProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final fontSize = ref.watch(fontSizeNotifierProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _PageHeader(title: '我的'),
          // User card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.hair(brightness)),
                boxShadow: AppTheme.cardShadow(brightness),
              ),
              child: InkWell(
                onTap: () => _showProfileSheet(context),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.tint(brightness),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 30, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('InfoFlow 用户',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 17,
                              )),
                          const SizedBox(height: 3),
                          Text(
                            '已订阅 ${RssSources.all.length} 个来源',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppTheme.hairStrong(brightness)),
                  ],
                ),
              ),
            ),
          ),
          // Reading stats
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('阅读统计', style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                  )),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        value: '${library.readIds.length}',
                        label: '已读',
                      ),
                      _StatItem(
                        value: () {
                          final secs = ref.watch(readingStatsProvider).totalReadSeconds;
                          final m = secs ~/ 60;
                          return m < 60 ? '${m}min' : '${(m / 60).toStringAsFixed(1)}h';
                        }(),
                        label: '阅读时长',
                      ),
                      _StatItem(
                        value: '${library.bookmarkCount}',
                        label: '收藏',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Appearance settings
          _SectionCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.dark_mode_rounded,
                  title: '深色模式',
                  trailing: _ThemeSeg(themeMode: themeMode),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.text_fields_rounded,
                  title: '正文字号',
                  trailing: Text(
                    _fontSizeLabel(fontSize),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  onTap: () => _showFontSizeSheet(context, ref, fontSize),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.language_rounded,
                  title: '语言',
                  trailing: Text('简体中文',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                      )),
                  onTap: () => _showLanguageSheet(context),
                ),
              ],
            ),
          ),
          // Feature entries
          _SectionCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.bookmark_border_rounded,
                  title: '我的收藏',
                  onTap: () => context.push('/bookmark'),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.rss_feed_rounded,
                  title: '订阅管理',
                  onTap: () => context.push('/subscription'),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.download_outlined,
                  title: '离线下载',
                  subtitle: '即将推出',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('离线下载功能开发中，敬请期待')),
                  ),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.radar_rounded,
                  title: '庄家雷达',
                  subtitle: '币安合约市场扫描',
                  onTap: () => context.push('/crypto-radar'),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.monetization_on_outlined,
                  title: '贵金属行情',
                  subtitle: '金价银价实时报价',
                  onTap: () => context.push('/metals'),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.smart_toy_rounded,
                  title: 'AI 模型排行',
                  subtitle: 'HuggingFace 趋势模型',
                  onTap: () => context.push('/ai-models'),
                ),
              ],
            ),
          ),
          // About
          _SectionCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.info_outline_rounded,
                  title: '关于 InfoFlow',
                  trailing: Text('v1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                      )),
                  onTap: () => _showAboutDialog(context),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.help_outline_rounded,
                  title: '帮助与反馈',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('帮助文档即将上线')),
                  ),
                ),
                _sep(context),
                _SettingItem(
                  icon: Icons.share_outlined,
                  title: '推荐给朋友',
                  onTap: () => Share.share(
                    '推荐你使用 InfoFlow，一款 AI 驱动的信息聚合 App',
                    subject: 'InfoFlow',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(height: 1,
          color: AppTheme.hair(Theme.of(context).brightness)),
    );
  }

  String _fontSizeLabel(double size) {
    if (size <= 13) return '小';
    if (size <= 16) return '中 · 16pt';
    if (size <= 19) return '大';
    return '特大';
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('个人资料', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 40,
                      color: Theme.of(ctx).colorScheme.primary),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('InfoFlow 用户',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('编辑个人资料', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('个人资料编辑功能即将上线')),
                  );
                },
                child: const Text('编辑资料'),
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
            Text('选择语言', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...languages.map((lang) => ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(lang.$1),
                  trailing: lang.$2 == 'zh_CN'
                      ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
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
            Text('版本: v1.0.0',
                style: Theme.of(ctx).textTheme.bodyMedium),
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
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('正文字号',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('${value.round()} pt',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  Slider(
                    value: value,
                    min: 12, max: 24, divisions: 6,
                    label: '${value.round()}',
                    onChanged: (v) => setState(() => value = v),
                    onChangeEnd: (v) =>
                        ref.read(fontSizeNotifierProvider.notifier).setFontSize(v),
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

class _ThemeSeg extends ConsumerWidget {
  final ThemeMode themeMode;
  const _ThemeSeg({required this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brand = theme.colorScheme.primary;
    final options = [
      ('跟随', ThemeMode.system),
      ('浅色', ThemeMode.light),
      ('深色', ThemeMode.dark),
    ];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.surface2(theme.brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final active = themeMode == opt.$2;
          return GestureDetector(
            onTap: () => ref
                .read(themeModeNotifierProvider.notifier)
                .setThemeMode(opt.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? (theme.brightness == Brightness.dark
                        ? AppTheme.tint(theme.brightness)
                        : theme.cardTheme.color)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: active
                    ? [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                      )]
                    : null,
              ),
              child: Text(
                opt.$1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? brand : theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  const _PageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.headlineLarge),
          const Spacer(),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.hair(brightness)),
          boxShadow: AppTheme.cardShadow(brightness),
        ),
        child: child,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        )),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.tint(brightness),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  )),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.warn(brightness),
                    )),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppTheme.hairStrong(brightness)),
          ],
        ),
      ),
    );
  }
}
