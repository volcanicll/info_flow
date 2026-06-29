import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ai_config.g.dart';

/// AI 配置：LLM API key 与 base url。
///
/// 配置了 key 后，AI 助手切换为真实 LLM 调用（OpenAI 兼容接口）；
/// 未配置则使用本地规则引擎。本设计只预留入口 + 持久化，
/// 真实 LLM 调用在 ai_chat 模块实现。
@Riverpod(keepAlive: true)
class AiConfig extends _$AiConfig {
  static const _kApiKey = 'ai_api_key';
  static const _kBaseUrl = 'ai_base_url';
  static const _kModel = 'ai_model';

  @override
  AiConfigState build() {
    _load();
    return const AiConfigState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AiConfigState(
      apiKey: prefs.getString(_kApiKey) ?? '',
      baseUrl: prefs.getString(_kBaseUrl) ?? 'https://api.openai.com/v1',
      model: prefs.getString(_kModel) ?? 'gpt-4o-mini',
    );
  }

  /// 是否启用真实 LLM
  bool get llmEnabled => state.apiKey.trim().isNotEmpty;

  Future<void> setConfig({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    state = AiConfigState(
      apiKey: apiKey ?? state.apiKey,
      baseUrl: baseUrl ?? state.baseUrl,
      model: model ?? state.model,
    );
    if (apiKey != null) await prefs.setString(_kApiKey, apiKey);
    if (baseUrl != null) await prefs.setString(_kBaseUrl, baseUrl);
    if (model != null) await prefs.setString(_kModel, model);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kApiKey);
    state = AiConfigState(baseUrl: state.baseUrl, model: state.model);
  }
}

class AiConfigState {
  final String apiKey;
  final String baseUrl;
  final String model;

  const AiConfigState({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
  });
}
