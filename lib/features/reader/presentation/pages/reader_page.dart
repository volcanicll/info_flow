import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ReaderPage extends ConsumerWidget {
  final String articleId;

  const ReaderPage({super.key, required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI 摘要',
            onPressed: () => _showSummary(context),
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: '翻译',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share('https://example.com/article/$articleId'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'bookmark':
                  break;
                case 'open_browser':
                  _launchUrl(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'bookmark', child: Text('收藏')),
              const PopupMenuItem(value: 'open_browser', child: Text('在浏览器中打开')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GPT-5 发布：多模态能力再升级，推理速度提升3倍',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('36', style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer,
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('36氪', style: theme.textTheme.titleSmall),
                      Text('2小时前 · 阅读5分钟', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('关注'),
                ),
              ],
            ),
            const Divider(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('AI 摘要', style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OpenAI 正式发布 GPT-5 模型，在多模态理解、长文本推理和代码生成方面均有显著提升。推理速度较 GPT-4 提升约3倍，同时成本降低60%。新模型支持原生图像生成和视频理解能力。',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _mockContent,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showSummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('AI 智能摘要', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildKeyPoint(context, 'GPT-5 推理速度较 GPT-4 提升3倍，成本降低60%'),
            _buildKeyPoint(context, '原生支持图像生成和视频理解能力'),
            _buildKeyPoint(context, '长文本处理能力从 128K 扩展到 1M tokens'),
            _buildKeyPoint(context, '新增 Agent 模式，支持自主任务规划和执行'),
            _buildKeyPoint(context, 'API 兼容 GPT-4，迁移成本极低'),
            const SizedBox(height: 16),
            Text(
              'OpenAI 正式发布 GPT-5 模型，在多模态理解、长文本推理和代码生成方面均有显著提升。推理速度较 GPT-4 提升约3倍，同时成本降低60%。新模型支持原生图像生成和视频理解能力，长文本处理从 128K 扩展到 1M tokens。新增 Agent 模式可自主规划和执行复杂任务。API 完全兼容 GPT-4，开发者可无缝迁移。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5))),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.parse('https://example.com/article/$articleId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

const _mockContent = '''
OpenAI 今日正式发布了备受期待的 GPT-5 模型，这是自 GPT-4 发布以来最大的一次模型升级。

多模态能力全面升级

GPT-5 在多模态理解方面实现了质的飞跃。新模型不仅能够理解和分析图像，还原生支持图像生成和视频理解能力。这意味着用户可以直接让模型分析视频内容、生成配图，甚至完成图文混排的创作任务。

推理速度大幅提升

据 OpenAI 官方数据，GPT-5 的推理速度较 GPT-4 提升了约3倍，同时 API 调用成本降低了60%。这一改进得益于全新的模型架构和优化后的推理引擎。

长文本处理能力突破

GPT-5 的上下文窗口从 GPT-4 的 128K tokens 扩展到了 1M tokens，这意味着用户可以一次性处理整本书籍或大型代码库。

Agent 模式

最令人兴奋的新功能是 Agent 模式。GPT-5 可以自主规划和执行复杂的多步骤任务，包括信息检索、代码编写、数据分析等。这为自动化工作流开辟了全新的可能性。

API 兼容性

OpenAI 表示，GPT-5 的 API 完全兼容 GPT-4，开发者只需更改模型名称即可完成迁移，无需修改任何代码。

GPT-5 现已向所有 API 用户开放，ChatGPT Plus 用户也可立即体验。
''';
