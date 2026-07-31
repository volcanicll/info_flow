import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/section_header.dart';

/// 目录式分组：栏目头（kicker + 衬线标题）+ 发丝线分隔的条目。
class ProfileSection extends StatelessWidget {
  final String kicker;
  final String title;
  final List<Widget> children;
  const ProfileSection({
    super.key,
    required this.kicker,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(kicker: kicker, title: title),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(),
            ),
          children[i],
        ],
      ],
    );
  }
}

/// 目录条目：标题居左，值以页码式右对齐；点击可导航。
class ProfileRow extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// 页码式右对齐值（如 v1.0.0 / 简体中文）。
  final String? value;

  /// 自定义右侧控件（覆盖 [value]）。
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    Widget? right = trailing;
    right ??= value != null
        ? Text(value!,
            style: theme.textTheme.bodyMedium?.copyWith(color: c.inkTertiary))
        : (onTap != null
            ? Icon(Icons.chevron_right_rounded, size: 20, color: c.hairlineStrong)
            : null);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: c.inkTertiary)),
                  ],
                ],
              ),
            ),
            if (right != null) ...[
              const SizedBox(width: 12),
              right,
            ],
          ],
        ),
      ),
    );
  }
}

/// 阅读统计：等宽数字 + 说明，竖向发丝线分隔。
class ProfileStats extends StatelessWidget {
  final List<({String value, String label})> items;
  const ProfileStats({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Hairline(vertical: true, length: 34, color: c.hairlineStrong),
            Expanded(
              child: _StatCell(value: items[i].value, label: items[i].label),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Column(
      children: [
        Text(value, style: AppTheme.mono(theme.textTheme.headlineLarge!)),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(color: c.inkTertiary)),
      ],
    );
  }
}
