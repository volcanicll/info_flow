import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/core/storage/kv_storage.dart';
import 'package:info_flow/features/ai_chat/data/ai_config.dart';
import 'package:info_flow/features/ai_chat/data/ai_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseOpenAiModelIds', () {
    test('解析标准 OpenAI /models 响应，保持服务端顺序', () {
      final models = parseOpenAiModelIds({
        'object': 'list',
        'data': [
          {'id': 'glm-5.3-flash', 'object': 'model'},
          {'id': 'kimi-k3', 'object': 'model'},
          {'id': 'deepseek-v4.1-flash'},
        ],
      });
      expect(models, ['glm-5.3-flash', 'kimi-k3', 'deepseek-v4.1-flash']);
    });

    test('脏数据容错：非字符串/空 id/重复项被跳过，结构非法返回空', () {
      expect(
        parseOpenAiModelIds({
          'data': [
            {'id': 'a'},
            {'id': '  '},
            {'id': 42},
            'junk',
            {'id': 'a'},
            {'other': 1},
          ],
        }),
        ['a'],
        reason: '空 id、非字符串与重复项跳过',
      );
      expect(parseOpenAiModelIds({'data': 'nope'}), isEmpty);
      expect(parseOpenAiModelIds('not a map'), isEmpty);
      expect(parseOpenAiModelIds(null), isEmpty);
    });

    test('OpenCode Go 网关真实响应形状可解析', () {
      final models = parseOpenAiModelIds({
        'object': 'list',
        'data': [
          {
            'id': 'minimax-m3',
            'object': 'model',
            'created': 1790526835,
            'owned_by': 'opencode',
          },
          {
            'id': 'glm-5.3-flash',
            'object': 'model',
            'created': 1790526835,
            'owned_by': 'opencode',
          },
        ],
      });
      expect(models, ['minimax-m3', 'glm-5.3-flash']);
    });
  });

  group('normalizeAiBaseUrl', () {
    test('去空白与结尾斜杠', () {
      expect(normalizeAiBaseUrl(' https://opencode.ai/zen/go/v1/ '),
          'https://opencode.ai/zen/go/v1');
      expect(normalizeAiBaseUrl('http://127.0.0.1:3425/v1///'),
          'http://127.0.0.1:3425/v1');
      expect(normalizeAiBaseUrl('https://api.openai.com/v1'),
          'https://api.openai.com/v1');
    });
  });

  group('AiConfig', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('默认 provider 为 openai，默认值取 openai 出厂配置', () {
      final cfg = container.read(aiConfigProvider);
      expect(cfg.provider, AiProviderKind.openai);
      expect(cfg.baseUrl, 'https://api.openai.com/v1');
      expect(cfg.model, 'gpt-4o-mini');
      expect(container.read(aiConfigProvider.notifier).llmEnabled, isFalse);
    });

    test('setConfig 持久化 provider/key/模型，llmEnabled 随 key 打开', () async {
      final notifier = container.read(aiConfigProvider.notifier);
      await notifier.setConfig(
        provider: AiProviderKind.opencode,
        apiKey: 'oc-go-key',
        baseUrl: 'https://opencode.ai/zen/go/v1',
        model: 'glm-5.3-flash',
      );

      final cfg = container.read(aiConfigProvider);
      expect(cfg.provider, AiProviderKind.opencode);
      expect(cfg.apiKey, 'oc-go-key');
      expect(cfg.model, 'glm-5.3-flash');
      expect(notifier.llmEnabled, isTrue);
      expect(prefs.getString('ai_provider'), 'opencode');
    });

    test('重启后从 SharedPreferences 恢复 opencode 配置', () async {
      await container.read(aiConfigProvider.notifier).setConfig(
            provider: AiProviderKind.opencode,
            apiKey: 'k',
            model: 'kimi-k3',
          );

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      final cfg = container2.read(aiConfigProvider);
      expect(cfg.provider, AiProviderKind.opencode);
      expect(cfg.model, 'kimi-k3');
    });

    test('opencodeSessionId 首次生成并持久化，之后稳定复用', () async {
      final notifier = container.read(aiConfigProvider.notifier);
      final id1 = notifier.opencodeSessionId();
      expect(id1, startsWith('infoflow-'));
      expect(notifier.opencodeSessionId(), id1);

      // 新容器（模拟重启）读同一份 prefs，会话 ID 不变
      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      expect(container2.read(aiConfigProvider.notifier).opencodeSessionId(), id1);
    });

    test('clear 只清 Key，provider 与模型配置保留', () async {
      final notifier = container.read(aiConfigProvider.notifier);
      await notifier.setConfig(
        provider: AiProviderKind.opencode,
        apiKey: 'k',
        model: 'glm-5.3-flash',
      );
      await notifier.clear();

      final cfg = container.read(aiConfigProvider);
      expect(cfg.provider, AiProviderKind.opencode);
      expect(cfg.apiKey, isEmpty);
      expect(cfg.model, 'glm-5.3-flash');
      expect(notifier.llmEnabled, isFalse);
    });

    test('每个 provider 有出厂默认值（含 OpenCode Go 官方云端网关）', () {
      expect(
        aiProviderDefaults[AiProviderKind.opencode]!.baseUrl,
        'https://opencode.ai/zen/go/v1',
      );
      expect(aiProviderDefaults[AiProviderKind.openai]!.baseUrl,
          'https://api.openai.com/v1');
    });
  });
}
