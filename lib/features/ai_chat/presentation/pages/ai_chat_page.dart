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
    final articleCount = ref.watch(articleCacheProvider).length;

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
              '本地规则 · $articleCount 篇文章可检索',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const _TypingIndicator();
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          // Quick questions — ALWAYS visible
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
              children: [
                _quickChip('今日要闻', Icons.whatshot_rounded, '今日要闻有哪些？'),
                _quickChip('推荐订阅源', Icons.rss_feed_rounded, '推荐一些优质订阅源'),
                _quickChip('趋势洞察', Icons.insights_rounded, '总结一下今日趋势洞察'),
                _quickChip('加密市场异动', Icons.trending_up_rounded, '加密市场有什么异动？'),
              ],
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

  Widget _quickChip(String label, IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _sendMessage(message),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.tint(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              )),
            ],
          ),
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
      context: context, isScrollControlled: true, showDragHandle: true,
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

// ─── Sub-Components ───────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _PageHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const Spacer(),
          if (trailing != null) trailing!,
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
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(6),
            bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(18),
          ),
          border: isUser ? null : Border.all(color: AppTheme.hair(brightness)),
          boxShadow: isUser ? null : AppTheme.cardShadow(brightness),
        ),
        child: isUser
            ? Text(message.text, style: TextStyle(
                fontSize: 14.5, height: 1.55, color: theme.colorScheme.onPrimary))
            : _MarkdownBody(text: message.text),
      ),
    );
  }
}

/// Simple markdown renderer for AI responses
class _MarkdownBody extends StatelessWidget {
  final String text;
  const _MarkdownBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = text.split('\n');
    final blocks = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) { blocks.add(const SizedBox(height: 6)); continue; }

      // Code block
      if (line.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) { codeLines.add(lines[i]); i++; }
        blocks.add(_CodeBlock(code: codeLines.join('\n')));
        continue;
      }
      // Heading
      if (line.startsWith('### ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(line.substring(4), style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        ));
        continue;
      }
      // Bold
      if (line.startsWith('**') && line.endsWith('**')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line.substring(2, line.length - 2), style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        ));
        continue;
      }
      // Bullet
      if (line.startsWith('- ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('• ', style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color)),
            Expanded(child: _RichTextInline(text: line.substring(2), theme: theme)),
          ]),
        ));
        continue;
      }
      // Numbered list
      final numMatch = RegExp(r'^(\d+)\.\s(.+)$').firstMatch(line);
      if (numMatch != null) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${numMatch.group(1)}. ', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
            Expanded(child: _RichTextInline(text: numMatch.group(2)!, theme: theme)),
          ]),
        ));
        continue;
      }
      // Blockquote
      if (line.startsWith('> ')) {
        blocks.add(Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
          ),
          child: Text(line.substring(2), style: TextStyle(
            fontSize: 13, fontStyle: FontStyle.italic,
            color: theme.textTheme.bodyMedium?.color, height: 1.5,
          )),
        ));
        continue;
      }
      // Regular text
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _RichTextInline(text: line, theme: theme),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }
}

class _RichTextInline extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _RichTextInline({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    final parts = text.split(RegExp(r'(\*\*[^*]+\*\*)'));
    return Text.rich(TextSpan(
      children: parts.map((p) {
        if (p.startsWith('**') && p.endsWith('**')) {
          return TextSpan(text: p.substring(2, p.length - 2), style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14,
              color: theme.textTheme.bodyLarge?.color, height: 1.55));
        }
        return TextSpan(text: p, style: TextStyle(
            fontSize: 14, height: 1.55, color: theme.textTheme.bodyLarge?.color));
      }).toList(),
    ));
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface2(theme.brightness),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(code, style: TextStyle(
          fontSize: 12.5, fontFamily: 'monospace', height: 1.5,
          color: theme.textTheme.bodyLarge?.color,
        )),
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
            topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(theme), const SizedBox(width: 5), _dot(theme), const SizedBox(width: 5), _dot(theme),
        ]),
      ),
    );
  }

  Widget _dot(ThemeData theme) => Container(
    width: 7, height: 7,
    decoration: BoxDecoration(
      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
      shape: BoxShape.circle,
    ),
  );
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.focusNode, required this.loading, required this.onSend});

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

  void _onFocusChange() => setState(() => _focused = widget.focusNode.hasFocus);

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
        border: Border(top: BorderSide(color: AppTheme.hair(brightness), width: 1)),
        color: theme.cardTheme.color,
      ),
      padding: EdgeInsets.fromLTRB(14, 10, 14, 16 + MediaQuery.paddingOf(context).bottom),
      child: Row(children: [
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
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: widget.loading ? AppTheme.surface2(brightness) : theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: widget.loading
                ? const Center(child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : Icon(Icons.send_rounded, size: 19, color: theme.colorScheme.onPrimary),
          ),
        ),
      ]),
    );
  }
}
