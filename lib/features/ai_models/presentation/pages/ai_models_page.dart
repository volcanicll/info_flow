import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../domain/models/ai_model_item.dart';
import '../controllers/ai_models_controller.dart';

class AiModelsPage extends ConsumerWidget {
  const AiModelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiModelsProvider);
    final notifier = ref.read(aiModelsProvider.notifier);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 18, 12),
            child: Row(
              children: [
                IconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 20, color: _hfGold),
                      const SizedBox(width: 8),
                      Text('AI 模型排行',
                          style: theme.textTheme.headlineLarge),
                    ],
                  ),
                ),
                if (state.status == AiModelsStatus.loading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconBtn(
                    icon: Icons.refresh_rounded,
                    onTap: () => notifier.loadModels(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, theme, brightness, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    Brightness brightness,
    AiModelsState state,
    AiModelsNotifier notifier,
  ) {
    switch (state.status) {
      case AiModelsStatus.idle:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.model_training, size: 64,
                    color: AppTheme.tint(brightness)),
                const SizedBox(height: 16),
                Text('点击刷新获取 HuggingFace\n趋势 AI 模型排行',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => notifier.loadModels(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('加载模型'),
                ),
              ],
            ),
          ),
        );
      case AiModelsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case AiModelsStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48,
                    color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('加载失败', style: theme.textTheme.titleMedium),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => notifier.loadModels(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      case AiModelsStatus.done:
        return RefreshIndicator(
          onRefresh: () => notifier.loadModels(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: state.models.length + 1,
            itemBuilder: (_, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.hair(brightness)),
                      boxShadow: AppTheme.cardShadow(brightness),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up,
                                size: 18, color: _hfGold),
                            const SizedBox(width: 8),
                            Text('HuggingFace 趋势模型',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontSize: 15,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('共 ${state.models.length} 个模型',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }
              final model = state.models[index - 1];
              return _ModelCard(model: model, brightness: brightness);
            },
          ),
        );
    }
  }
}

const _hfGold = Color(0xFFFFD21E);

class _ModelCard extends StatelessWidget {
  final AiModelItem model;
  final Brightness brightness;
  const _ModelCard({required this.model, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface2(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.hair(brightness)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _hfGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      size: 20, color: _hfGold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(model.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            if (model.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(model.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _Tag(
                  icon: Icons.download_outlined,
                  label: model.downloadsFormatted,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _Tag(
                  icon: Icons.favorite_border,
                  label: '${model.likes}',
                  color: AppTheme.love(brightness),
                ),
                if (model.pipelineTag != null) ...[
                  const SizedBox(width: 8),
                  _Tag(
                    icon: Icons.category_outlined,
                    label: model.pipelineTag!,
                    color: AppTheme.warn(brightness),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          )),
        ],
      ),
    );
  }
}


