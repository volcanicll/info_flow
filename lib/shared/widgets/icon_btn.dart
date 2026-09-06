import 'package:flutter/material.dart';

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;
  final String? semanticsLabel;

  const IconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.tooltip,
    this.semanticsLabel,
  });

  String? _inferLabel(IconData icon) {
    if (icon == Icons.arrow_back ||
        icon == Icons.arrow_back_rounded ||
        icon == Icons.arrow_back_ios ||
        icon == Icons.arrow_back_ios_new) {
      return '返回';
    }
    if (icon == Icons.close || icon == Icons.close_rounded) {
      return '关闭';
    }
    if (icon == Icons.refresh || icon == Icons.refresh_rounded) {
      return '刷新';
    }
    if (icon == Icons.search || icon == Icons.search_rounded) {
      return '搜索';
    }
    if (icon == Icons.add || icon == Icons.add_rounded) {
      return '添加';
    }
    if (icon == Icons.share ||
        icon == Icons.share_rounded ||
        icon == Icons.ios_share ||
        icon == Icons.ios_share_rounded) {
      return '分享';
    }
    if (icon == Icons.tune ||
        icon == Icons.tune_rounded ||
        icon == Icons.settings ||
        icon == Icons.settings_rounded) {
      return '设置';
    }
    if (icon == Icons.more_horiz ||
        icon == Icons.more_horiz_rounded ||
        icon == Icons.more_vert ||
        icon == Icons.more_vert_rounded) {
      return '更多选项';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticsLabel ?? tooltip ?? _inferLabel(icon);

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(icon, size: 22),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    if (effectiveLabel != null) {
      button = Semantics(
        button: true,
        label: effectiveLabel,
        child: button,
      );
    }

    return button;
  }
}
