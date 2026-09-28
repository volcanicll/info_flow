import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/ai_service.dart';

part 'chat_controller.g.dart';

/// 单条对话消息（访谈排版：AI 为受访者引述，用户为提问者）。
class ChatMessage {
  final String text;
  final bool isUser;

  /// 生成失败的错误气泡：可点击重试，不参与后续上下文。
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

/// 会话状态：消息列表 + 是否正在等待 AI 回复。
class ChatState {
  final List<ChatMessage> messages;
  final bool sending;

  const ChatState({required this.messages, this.sending = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? sending}) {
    return ChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
    );
  }
}

/// 开场白：AI 助手的自我介绍。
const _welcome = ChatMessage(
  isUser: false,
  text: '你好！我是 InfoFlow AI 助手，可以帮你：\n\n'
      '• 总结已订阅文章的核心内容\n'
      '• 回答关于订阅内容的问题\n'
      '• 推荐优质订阅源\n\n'
      '试试问我「今日要闻」吧！',
);

/// 会话控制器：集中管理消息流与发送态，页面退化为纯 UI。
///
/// send/retry 全程兜底异常：任何失败都以错误气泡收尾并复位 sending，
/// 保证输入框与打字指示不会永久卡在「正在思考…」。
@riverpod
class ChatController extends _$ChatController {
  @override
  ChatState build() => const ChatState(messages: [_welcome]);

  /// 发送一条用户消息并等待 AI 回复。sending 期间忽略重复发送。
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: trimmed, isUser: true)],
      sending: true,
    );

    await _request(trimmed);
  }

  /// 重试最后一条失败的消息：移除错误气泡，重新请求其前面的用户消息。
  Future<void> retry() async {
    if (state.sending) return;
    final msgs = state.messages;
    if (msgs.isEmpty || msgs.last.isUser || !msgs.last.isError) return;

    String? lastUser;
    for (final m in msgs.reversed) {
      if (m.isUser) {
        lastUser = m.text;
        break;
      }
    }
    if (lastUser == null) return;

    state = state.copyWith(
      messages: msgs.sublist(0, msgs.length - 1),
      sending: true,
    );
    await _request(lastUser);
  }

  Future<void> _request(String text) async {
    try {
      final reply = await ref.read(aiServiceProvider).reply(text);
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(text: reply, isUser: false)],
        sending: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          const ChatMessage(
            isUser: false,
            isError: true,
            text: '回复生成失败，请检查网络或稍后重试。',
          ),
        ],
        sending: false,
      );
    }
  }
}
