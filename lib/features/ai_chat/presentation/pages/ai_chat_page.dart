import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/ai_config.dart';
import '../../../feed/presentation/controllers/article_cache.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_view.dart';

/// AI 助手页（访谈排版）：受访者引述块 + 提问者右对齐，会话状态托管于
/// [ChatController]，本页仅负责编排与滚动。
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    ref.read(chatControllerProvider.notifier).send(text);
    _scrollToBottom();
  }

  void _sendCurrent() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _send(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatControllerProvider);
    final articleCount = ref.watch(articleCacheProvider).length;

    // 消息增减后滚到底部。
    ref.listen(chatControllerProvider, (prev, next) {
      if (prev == null || next.messages.length != prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Masthead(theme: theme, articleCount: articleCount, onSettings: () => _showSettings(context)),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: state.messages.length + (state.sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.messages.length) {
                    return const ChatTypingIndicator();
                  }
                  return ChatMessageView(message: state.messages[index]);
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
                children: [
                  _QuickTag(label: '每日播报', onTap: () => _send('每日播报')),
                  _QuickTag(label: '聪明钱情报', onTap: () => _send('解读一下当前聪明钱（大户钱包）的动向和值得关注的信号')),
                  _QuickTag(label: '今日要闻', onTap: () => _send('今日要闻有哪些？')),
                  _QuickTag(label: '推荐订阅源', onTap: () => _send('推荐一些优质订阅源')),
                  _QuickTag(label: '趋势洞察', onTap: () => _send('总结一下今日趋势洞察')),
                  _QuickTag(label: '加密市场异动', onTap: () => _send('加密市场有什么异动？')),
                ],
              ),
            ),
            ChatInputBar(
              controller: _inputController,
              focusNode: _focusNode,
              sending: state.sending,
              onSend: _sendCurrent,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final config = ref.read(aiConfigProvider);
    final keyCtrl = TextEditingController(text: config.apiKey);
    final urlCtrl = TextEditingController(text: config.baseUrl);
    final modelCtrl = TextEditingController(text: config.model);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI 设置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('配置后 AI 助手将接入真实大模型；留空则使用本地模式。',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'API Base URL', hintText: 'https://api.openai.com/v1')),
            const SizedBox(height: 12),
            TextField(controller: keyCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'API Key', hintText: 'sk-...')),
            const SizedBox(height: 12),
            TextField(controller: modelCtrl,
                decoration: const InputDecoration(labelText: '模型名称', hintText: 'gpt-4o-mini')),
            const SizedBox(height: 20),
            Row(children: [
              TextButton(
                onPressed: () async {
                  await ref.read(aiConfigProvider.notifier).clear();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('清除 Key'),
              ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await ref.read(aiConfigProvider.notifier).setConfig(
                    apiKey: keyCtrl.text.trim(),
                    baseUrl: urlCtrl.text.trim().isNotEmpty ? urlCtrl.text.trim() : null,
                    model: modelCtrl.text.trim().isNotEmpty ? modelCtrl.text.trim() : null,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// 报头：kicker + 衬线标题 + 检索到的文章数 + 设置入口。
class _Masthead extends StatelessWidget {
  final ThemeData theme;
  final int articleCount;
  final VoidCallback onSettings;
  const _Masthead({required this.theme, required this.articleCount, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI 访谈 · 本地规则',
                        style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
                    const SizedBox(height: 2),
                    Text('AI 助手', style: theme.textTheme.displayMedium),
                    const SizedBox(height: 2),
                    Text('$articleCount 篇文章可检索',
                        style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary)),
                  ],
                ),
              ),
              IconBtn(icon: Icons.tune_rounded, onTap: onSettings),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Hairline(color: c.hairlineStrong),
        ),
      ],
    );
  }
}

/// 快捷提问：铅字标签样式（细线描边，无底色）。
class _QuickTag extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickTag({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: c.hairlineStrong, width: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label,
              style: theme.textTheme.labelLarge?.copyWith(color: c.inkSecondary)),
        ),
      ),
    );
  }
}
