import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/models/ai_model_item.dart';
import '../controllers/ai_models_controller.dart';

/// AI 模型排行（榜单目录）：排名序号 + 衬线模型名 + 等宽指标，发丝线分隔。
class AiModelsPage extends ConsumerWidget {
  const AiModelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiModelsProvider);
    final notifier = ref.read(aiModelsProvider.notifier);
    final theme = Theme.of(context);
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MODELS · HuggingFace',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: c.accent)),
                        const SizedBox(height: 2),
                        Text('AI 模型', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                  if (state.status == AiModelsStatus.loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconBtn(
                        icon: Icons.refresh_rounded,
                        onTap: () => notifier.loadModels()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            Expanded(child: _body(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AiModelsState state, AiModels notifier) {
    switch (state.status) {
      case AiModelsStatus.idle:
        return _ModelsMessage(
          icon: Icons.auto_awesome_outlined,
          title: '榜单待命',
          subtitle: '获取 HuggingFace 趋势 AI 模型排行',
          actionLabel: '加载模型',
          onAction: notifier.loadModels,
        );
      case AiModelsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case AiModelsStatus.error:
        return _ModelsMessage(
          icon: Icons.error_outline_rounded,
          title: '加载失败',
          subtitle: state.error ?? '未知错误',
          actionLabel: '重试',
          onAction: notifier.loadModels,
        );
      case AiModelsStatus.done:
        return RefreshIndicator(
          onRefresh: () => notifier.loadModels(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              SectionHeader(
                kicker: 'TRENDING · 趋势榜',
                title: '模型排行',
                trailing: Text('${state.models.length}',
                    style: AppTheme.mono(Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(
                          color: context.colors.inkTertiary,
                          fontWeight: FontWeight.w700,
                        ))),
              ),
              for (var i = 0; i < state.models.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Hairline(),
                  ),
                _ModelRow(rank: i + 1, model: state.models[i]),
              ],
            ],
          ),
        );
    }
  }
}

/// 榜单行：排名序号 + 模型名 + 描述 + 指标标签（下载/点赞/任务）。
class _ModelRow extends StatelessWidget {
  final int rank;
  final AiModelItem model;
  const _ModelRow({required this.rank, required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: AppTheme.mono(theme.textTheme.titleLarge!
                  .copyWith(color: rank <= 3 ? c.accent : c.inkTertiary)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (model.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(model.description,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: c.inkTertiary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _Metric(
                        icon: Icons.download_outlined,
                        label: model.downloadsFormatted),
                    _Metric(
                        icon: Icons.favorite_border_rounded,
                        label: '${model.likes}'),
                    if (model.pipelineTag != null)
                      _Metric(
                          icon: Icons.category_outlined,
                          label: model.pipelineTag!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 指标：细线图标 + 等宽数值。
class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c.inkTertiary),
        const SizedBox(width: 4),
        Text(label,
            style: AppTheme.mono(
                theme.textTheme.labelMedium!.copyWith(color: c.inkSecondary))),
      ],
    );
  }
}

/// 空闲 / 错误态。
class _ModelsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  const _ModelsMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: c.hairlineStrong),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
