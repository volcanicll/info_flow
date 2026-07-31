import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/ai_chat/data/ai_service.dart';
import 'package:info_flow/features/ai_chat/presentation/controllers/chat_controller.dart';

/// 假 AI 服务：回声回复，可控延迟，避免真实网络/文章缓存依赖。
class _FakeAiService extends AiService {
  _FakeAiService(super.ref);

  @override
  Future<String> reply(String userMessage) async {
    await Future<void>.delayed(Duration.zero);
    return 'echo: $userMessage';
  }
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      aiServiceProvider.overrideWith(_FakeAiService.new),
    ]);
    addTearDown(container.dispose);
    // 保持 autoDispose provider 存活
    container.listen(chatControllerProvider, (_, _) {});
  });

  group('ChatController', () {
    test('初始状态：仅开场白，非发送态', () {
      final s = container.read(chatControllerProvider);
      expect(s.messages.length, 1);
      expect(s.messages.single.isUser, false);
      expect(s.sending, false);
    });

    test('send 追加用户消息与 AI 回复，结束后 sending 复位', () async {
      final n = container.read(chatControllerProvider.notifier);
      final future = n.send('今日要闻');

      // 发送中：用户消息已入列，sending 为 true
      final mid = container.read(chatControllerProvider);
      expect(mid.sending, true);
      expect(mid.messages.last.isUser, true);
      expect(mid.messages.last.text, '今日要闻');

      await future;
      final done = container.read(chatControllerProvider);
      expect(done.sending, false);
      expect(done.messages.length, 3);
      expect(done.messages.last.isUser, false);
      expect(done.messages.last.text, 'echo: 今日要闻');
    });

    test('空白消息被忽略', () async {
      await container.read(chatControllerProvider.notifier).send('   ');
      expect(container.read(chatControllerProvider).messages.length, 1);
    });

    test('sending 期间忽略重复发送', () async {
      final n = container.read(chatControllerProvider.notifier);
      final first = n.send('第一条');
      await n.send('第二条'); // sending 中，应被忽略
      await first;
      final s = container.read(chatControllerProvider);
      // 开场白 + 用户第一条 + AI 回复
      expect(s.messages.length, 3);
      expect(s.messages.any((m) => m.text == '第二条'), false);
    });
  });
}
