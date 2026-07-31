import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../controllers/chat_controller.dart';

/// 单条消息（访谈排版）：
/// - AI 回复 → 受访者引述块：小号 kicker + 左侧细竖线 + 衬线正文，无气泡底色。
/// - 用户消息 → 右对齐墨色提问，无气泡底色。
class ChatMessageView extends StatelessWidget {
  final ChatMessage message;
  const ChatMessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 22, left: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('你', style: theme.textTheme.labelMedium?.copyWith(color: c.inkTertiary)),
            const SizedBox(height: 4),
            Text(
              message.text,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INFOFLOW AI',
              style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.accent, width: 2)),
            ),
            child: _MarkdownBody(text: message.text),
          ),
        ],
      ),
    );
  }
}

/// 打字指示：受访者思考中的三点。
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INFOFLOW AI',
              style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.accent, width: 2)),
            ),
            child: Text('正在思考…', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// 极简 markdown 渲染：标题用衬线、列表/引用用发丝线语言。
class _MarkdownBody extends StatelessWidget {
  final String text;
  const _MarkdownBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final lines = text.split('\n');
    final blocks = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        blocks.add(const SizedBox(height: 6));
        continue;
      }
      if (line.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(_CodeBlock(code: codeLines.join('\n')));
        continue;
      }
      if (line.startsWith('### ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(line.substring(4), style: theme.textTheme.titleMedium),
        ));
        continue;
      }
      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(line.substring(2, line.length - 2),
              style: theme.textTheme.titleSmall),
        ));
        continue;
      }
      if (line.startsWith('- ') || line.startsWith('• ')) {
        blocks.add(_bullet(theme, c, line.substring(2)));
        continue;
      }
      final numMatch = RegExp(r'^(\d+)\.\s(.+)$').firstMatch(line);
      if (numMatch != null) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${numMatch.group(1)}.  ',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: c.accent, fontWeight: FontWeight.w700)),
            Expanded(child: _RichInline(text: numMatch.group(2)!)),
          ]),
        ));
        continue;
      }
      if (line.startsWith('> ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(line.substring(2),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: c.inkSecondary,
              )),
        ));
        continue;
      }
      if (line.startsWith('---')) {
        blocks.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(height: 0.5, color: c.hairline),
        ));
        continue;
      }
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _RichInline(text: line),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  Widget _bullet(ThemeData theme, AppColors c, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Container(width: 3, height: 3, color: c.accent),
        ),
        Expanded(child: _RichInline(text: content)),
      ]),
    );
  }
}

/// 行内富文本：处理 **加粗** 片段。
class _RichInline extends StatelessWidget {
  final String text;
  const _RichInline({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge;
    final parts = text.split(RegExp(r'(\*\*[^*]+\*\*)'));
    return Text.rich(TextSpan(
      children: parts.map((p) {
        if (p.startsWith('**') && p.endsWith('**')) {
          return TextSpan(
            text: p.substring(2, p.length - 2),
            style: base?.copyWith(fontWeight: FontWeight.w700),
          );
        }
        return TextSpan(text: p, style: base);
      }).toList(),
    ));
  }
}

/// 代码块：等宽 + 纸底次级色，无阴影。
class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.hairline, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: AppTheme.mono(TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: c.ink,
          )),
        ),
      ),
    );
  }
}
