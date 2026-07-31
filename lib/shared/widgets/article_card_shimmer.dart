import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 目录行骨架屏：文字行式灰条，模拟杂志排版结构（无卡片、无阴影）。
class ArticleCardShimmer extends StatelessWidget {
  const ArticleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bar = c.surface2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(70, 10.5, bar),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(null, 17, bar),
                    const SizedBox(height: 7),
                    _box(null, 17, bar),
                    const SizedBox(height: 10),
                    _box(200, 13, bar),
                    const SizedBox(height: 5),
                    _box(150, 13, bar),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _box(96, 96, bar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box(double? w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
