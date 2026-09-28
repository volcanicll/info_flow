import 'package:flutter/material.dart';

import 'skeleton_box.dart';

/// 目录行骨架屏：文字行式灰条，模拟杂志排版结构（无卡片、无阴影）。
/// 灰条带脉冲呼吸动画（SkeletonBox），与全站加载态统一。
class ArticleCardShimmer extends StatelessWidget {
  const ArticleCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 70, height: 10.5),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 17),
                    SizedBox(height: 7),
                    SkeletonBox(height: 17),
                    SizedBox(height: 10),
                    SkeletonBox(width: 200, height: 13),
                    SizedBox(height: 5),
                    SkeletonBox(width: 150, height: 13),
                  ],
                ),
              ),
              SizedBox(width: 14),
              SkeletonBox(width: 96, height: 96),
            ],
          ),
        ],
      ),
    );
  }
}
