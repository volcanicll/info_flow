import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:info_flow/core/storage/kv_storage.dart';

part 'ai_config.g.dart';

/// AI 接入方式。
enum AiProviderKind {
  /// 通用 OpenAI 兼容接口（任意厂商 / 中转）
  openai,

  /// OpenCode Go 官方接入：本地网关（magpie，默认 127.0.0.1:3425/v1），
  /// 与 opencode 官方客户端同源的 OpenAI 兼容协议
  opencode,
}

/// 每个 provider 的出厂默认值（未手动配置过时使用）。
///
/// OpenCode Go 官方接入：云端网关 `https://opencode.ai/zen/go/v1`，
/// OpenAI 兼容（chat/completions + /models），API Key 在 opencode.ai/auth
/// 订阅 Go 后获取；桌面端本地网关（127.0.0.1:3425）仅限本机客户端使用，
/// 不作为 App 默认值。
const aiProviderDefaults = <AiProviderKind, ({String baseUrl, String model})>{
  AiProviderKind.openai: (
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-4o-mini',
  ),
  AiProviderKind.opencode: (
    baseUrl: 'https://opencode.ai/zen/go/v1',
    model: 'glm-5.3-flash',
  ),
};

/// AI 配置：provider、LLM API key 与 base url。
///
/// 两种接入方式均为 OpenAI 兼容协议（/chat/completions + Bearer）：
/// 配置了 key 后，AI 助手切换为真实 LLM 调用；未配置则使用本地规则引擎。
@Riverpod(keepAlive: true)
class AiConfig extends _$AiConfig {
  static const _kProvider = 'ai_provider';
  static const _kApiKey = 'ai_api_key';
  static const _kBaseUrl = 'ai_base_url';
  static const _kModel = 'ai_model';
  static const _kOcSession = 'ai_opencode_session_id';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  AiProviderKind _readProvider() {
    final saved = _prefs.getString(_kProvider);
    return AiProviderKind.values
            .where((p) => p.name == saved)
            .firstOrNull ??
        AiProviderKind.openai;
  }

  @override
  AiConfigState build() {
    final provider = _readProvider();
    final defaults = aiProviderDefaults[provider]!;
    return AiConfigState(
      provider: provider,
      apiKey: _prefs.getString(_kApiKey) ?? '',
      baseUrl: _prefs.getString(_kBaseUrl) ?? defaults.baseUrl,
      model: _prefs.getString(_kModel) ?? defaults.model,
    );
  }

  /// 是否启用真实 LLM（两种 provider 均以 key 为开关）
  bool get llmEnabled => state.apiKey.trim().isNotEmpty;

  /// OpenCode Go 官方客户端要求每个会话携带稳定的 `x-opencode-session`
  /// ID（官方识别与限流用）。首次调用生成并持久化，之后跨启动复用。
  String opencodeSessionId() {
    final existing = _prefs.getString(_kOcSession);
    if (existing != null && existing.isNotEmpty) return existing;
    final rand = math.Random.secure();
    final id = 'infoflow-${DateTime.now().millisecondsSinceEpoch}'
        '-${List.generate(4, (_) => rand.nextInt(16).toRadixString(16)).join()}';
    _prefs.setString(_kOcSession, id);
    return id;
  }

  Future<void> setConfig({
    required AiProviderKind provider,
    String? apiKey,
    String? baseUrl,
    String? model,
  }) async {
    state = AiConfigState(
      provider: provider,
      apiKey: apiKey ?? state.apiKey,
      baseUrl: baseUrl ?? state.baseUrl,
      model: model ?? state.model,
    );
    await _prefs.setString(_kProvider, provider.name);
    if (apiKey != null) await _prefs.setString(_kApiKey, apiKey);
    if (baseUrl != null) await _prefs.setString(_kBaseUrl, baseUrl);
    if (model != null) await _prefs.setString(_kModel, model);
  }

  Future<void> clear() async {
    await _prefs.remove(_kApiKey);
    state = AiConfigState(
      provider: state.provider,
      baseUrl: state.baseUrl,
      model: state.model,
    );
  }
}

class AiConfigState {
  final AiProviderKind provider;
  final String apiKey;
  final String baseUrl;
  final String model;

  const AiConfigState({
    this.provider = AiProviderKind.openai,
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
  });

  /// 当前 provider 的出厂默认 baseUrl / model（UI 切换 provider 时智能回填用）
  ({String baseUrl, String model}) get defaults =>
      aiProviderDefaults[provider]!;
}
