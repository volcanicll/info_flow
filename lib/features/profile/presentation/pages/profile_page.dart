import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/library_store.dart';
import '../../../../core/state/reading_stats.dart';
import '../../../../core/storage/kv_storage.dart';
import '../../../feed/data/rss_sources.dart';

/// 我的页
///
/// 统计真实化；深色模式 / 字体大小设置真实生效并持久化。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final library = ref.watch(libraryStoreProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final fontSize = ref.watch(fontSizeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 用户信息卡片
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: theme.brightness == Brightness.dark
                            ? const [Color(0xFF9B9BF5), Color(0xFFA78BFA)]
                            : const [Color(0xFF5B5BD6), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('InfoFlow 用户',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '已订阅 ${RssSources.all.length} 个来源',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
          // 阅读统计
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('阅读统计', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: '已读',
                        value: '${library.readIds.length}',
                        icon: Icons.article_rounded,
                      ),
                      _StatItem(
                        label: '阅读时长',
                        value: () {
                          final secs = ref.watch(readingStatsProvider).totalReadSeconds;
                          final m = secs ~/ 60;
                          return m < 60 ? '${m}min' : '${(m / 60).toStringAsFixed(1)}h';
                        }(),
                        icon: Icons.schedule_rounded,
                      ),
                      _StatItem(
                        label: '收藏',
                        value: '${library.bookmarkCount}',
                        icon: Icons.bookmark_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 外观设置
          _SectionCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.dark_mode_rounded,
                  title: '深色模式',
                  trailing: _ThemeModeMenu(current: themeMode),
                ),
                _Divider(),
                _SettingItem(
                  icon: Icons.text_fields_rounded,
                  title: '正文字号',
                  trailing: Text(
                    _fontSizeLabel(fontSize),
                    style: theme.textTheme.bodyMedium,
                  ),
                  onTap: () => _showFontSizeSheet(context, ref, fontSize),
                ),
                _SettingItem(
                  icon: Icons.language_rounded,
                  title: '语言',
                  trailing: Text('简体中文',
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          // 功能
          _SectionCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.bookmark_outline_rounded,
                  title: '我的收藏',
                  onTap: () => context.push('/bookmark'),
                ),
                _Divider(),
                _SettingItem(
                  icon: Icons.rss_feed_rounded,
                  title: '订阅管理',
                  onTap: () => context.push('/subscription'),
                ),
                _Divider(),
                _SettingItem(
                  icon: Icons.download_outlined,
                  title: '离线下载',
                  subtitle: '即将推出',
                ),
              ],
            ),
          ),
          // 关于
          _SectionCard(
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.info_outline_rounded,
                  title: '关于 InfoFlow',
                  trailing: const Text('v1.0.0',
                      style: TextStyle(color: Colors.grey)),
                ),
                _Divider(),
                _SettingItem(
                    icon: Icons.help_outline_rounded, title: '帮助与反馈'),
                _Divider(),
                _SettingItem(
                    icon: Icons.share_outlined, title: '推荐给朋友'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fontSizeLabel(double size) {
    if (size <= 13) return '小';
    if (size <= 16) return '中';
    if (size <= 19) return '大';
    return '特大';
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
                  Text(
                    '${value.round()} pt',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: 12,
                    max: 24,
                    divisions: 6,
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

/// 深色模式三态选择菜单
class _ThemeModeMenu extends ConsumerWidget {
  final ThemeMode current;
  const _ThemeModeMenu({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<ThemeMode>(
      onSelected: (mode) =>
          ref.read(themeModeNotifierProvider.notifier).setThemeMode(mode),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_label(current), style: theme.textTheme.bodyMedium),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded,
              size: 18, color: theme.colorScheme.outline),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
        const PopupMenuItem(value: ThemeMode.light, child: Text('浅色')),
        const PopupMenuItem(value: ThemeMode.dark, child: Text('深色')),
      ],
    );
  }

  String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF5B5BD6).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            )),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
          height: 1, thickness: 0.5, color: Theme.of(context).dividerColor),
    );
  }
}
