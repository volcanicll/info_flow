import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// 会话输入栏（访谈风）：无圆角气泡，仅底部粗墨线 + 极简发送。
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  void _onFocusChange() => setState(() => _focused = widget.focusNode.hasFocus);

  void _onTextChange() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final lineColor = _focused ? c.accent : c.hairlineStrong;

    return Container(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: lineColor, width: 1.5),
                ),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: !widget.sending,
                minLines: 1,
                maxLines: 4,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: '问我任何关于订阅内容的问题…',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 8),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _SendButton(
            sending: widget.sending,
            enabled: _hasText && !widget.sending,
            onTap: widget.onSend,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool sending;
  final bool enabled;
  final VoidCallback onTap;
  const _SendButton({
    required this.sending,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 40,
        height: 40,
        child: sending
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.inkTertiary,
                  ),
                ),
              )
            : Icon(
                Icons.arrow_upward_rounded,
                size: 24,
                color: enabled ? c.ink : c.hairlineStrong,
              ),
      ),
    );
  }
}
