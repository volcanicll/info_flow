import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/state/ai_config.dart';
import '../../../../core/state/article_cache.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../data/ai_service.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: '你好！我是 InfoFlow AI 助手，可以帮你：\n\n'
          '• 总结已订阅文章的核心内容\n'
          '• 回答关于订阅内容的问题\n'
          '• 推荐优质订阅源\n\n'
          '试试问我「今日要闻」吧！',
      isUser: false,
    ));
  }

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
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendCurrentMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _loading) return;
    _sendMessage(text);
    _inputController.clear();
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    final reply = await ref.read(aiServiceProvider).reply(text);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _PageHeader(
            title: 'AI 助手',
            trailing: IconBtn(
              icon: Icons.auto_awesome_rounded,
              onTap: () => _showSettings(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              '本地规则 · ${ref.watch(articleCacheProvider).length} 篇文章可检索',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12, fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_messages.length <= 1)
            SizedBox(
              height: 44,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                child: Row(
                  children: [
                    _QuickChip(label: '今日要闻', icon: Icons.whatshot_rounded, onTap: () => _sendMessage('今日要闻有哪些？')),
                    _QuickChip(label: '推荐订阅源', icon: Icons.rss_feed_rounded, onTap: () => _sendMessage('推荐一些优质订阅源')),
                    _QuickChip(label: '总结 GPT-5', icon: Icons.auto_awesome_rounded, onTap: () => _sendMessage('总结 GPT-5 文章')),
                    _QuickChip(label: '新闻亮点', icon: Icons.auto_awesome_rounded, onTap: () => _sendMessage('今天有什么新闻亮点？')),
                    _QuickChip(label: '今日洞察', icon: Icons.insights_rounded, onTap: () => _sendMessage('总结一下今日趋势洞察')),
                    _QuickChip(label: '加密市场异动', icon: Icons.trending_up_rounded, onTap: () => _sendMessage('加密市场有什么异动？')),
                  ],
                ),
              ),
            ),
          _InputBar(
            controller: _inputController,
            focusNode: _focusNode,
            loading: _loading,
            onSend: _sendCurrentMessage,
          ),
        ],
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
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI 设置', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '配置后 AI 助手将接入真实大模型；留空则使用本地模式。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'https://api.openai.com/v1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: 'gpt-4o-mini',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref.read(aiConfigProvider.notifier).clear();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('清除 Key'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      await ref.read(aiConfigProvider.notifier).setConfig(
                            apiKey: keyCtrl.text.trim(),
                            baseUrl: urlCtrl.text.trim().isNotEmpty
                                ? urlCtrl.text.trim() : null,
                            model: modelCtrl.text.trim().isNotEmpty
                                ? modelCtrl.text.trim() : null,
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _PageHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.headlineLarge),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18) : const Radius.circular(6),
            bottomRight: isUser
                ? const Radius.circular(6) : const Radius.circular(18),
          ),
          border: isUser
              ? null : Border.all(color: AppTheme.hair(brightness)),
          boxShadow: isUser ? null : AppTheme.cardShadow(brightness),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.55,
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(theme),
            const SizedBox(width: 5),
            _dot(theme),
            const SizedBox(width: 5),
            _dot(theme),
          ],
        ),
      ),
    );
  }

  Widget _dot(ThemeData theme) {
    return Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.tint(brightness),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: theme.colorScheme.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final borderColor = _focused
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : AppTheme.hair(brightness);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.hair(brightness), width: 1),
        ),
        color: theme.cardTheme.color,
      ),
      padding: EdgeInsets.fromLTRB(
        14, 10, 14, 16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface2(brightness),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor, width: 1.3),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: !widget.loading,
                decoration: const InputDecoration(
                  hintText: '问我任何关于你订阅内容的问题…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
          ),
          const SizedBox(width: 9),
          GestureDetector(
            onTap: widget.loading ? null : widget.onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.loading
                    ? AppTheme.surface2(brightness)
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: widget.loading
                  ? const Center(
                      child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      ),
                    )
                  : Icon(Icons.send_rounded,
                      size: 19, color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
