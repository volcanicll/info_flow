import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // 用户信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person, size: 32, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('InfoFlow 用户', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('点击登录', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          // 阅读统计
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本周阅读', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: '文章数', value: '23', icon: Icons.article),
                      _StatItem(label: '阅读时长', value: '2.5h', icon: Icons.schedule),
                      _StatItem(label: '收藏数', value: '8', icon: Icons.bookmark),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 设置列表
          Card(
            child: Column(
              children: [
                _SettingItem(icon: Icons.dark_mode, title: '深色模式', trailing: Switch(value: false, onChanged: (_) {})),
                _SettingItem(icon: Icons.text_fields, title: '字体大小', trailing: const Text('中')),
                _SettingItem(icon: Icons.notifications_outlined, title: '通知设置'),
                _SettingItem(icon: Icons.download_outlined, title: '离线下载'),
                _SettingItem(icon: Icons.language, title: '语言', trailing: const Text('简体中文')),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                _SettingItem(icon: Icons.help_outline, title: '帮助与反馈'),
                _SettingItem(icon: Icons.info_outline, title: '关于 InfoFlow'),
                _SettingItem(icon: Icons.share_outlined, title: '推荐给朋友'),
                _SettingItem(icon: Icons.cloud_upload_outlined, title: '数据导出'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
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
  final Widget? trailing;

  const _SettingItem({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: () {},
    );
  }
}
