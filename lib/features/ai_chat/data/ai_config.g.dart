// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AI 配置：provider、LLM API key 与 base url。
///
/// 两种接入方式均为 OpenAI 兼容协议（/chat/completions + Bearer）：
/// 配置了 key 后，AI 助手切换为真实 LLM 调用；未配置则使用本地规则引擎。

@ProviderFor(AiConfig)
final aiConfigProvider = AiConfigProvider._();

/// AI 配置：provider、LLM API key 与 base url。
///
/// 两种接入方式均为 OpenAI 兼容协议（/chat/completions + Bearer）：
/// 配置了 key 后，AI 助手切换为真实 LLM 调用；未配置则使用本地规则引擎。
final class AiConfigProvider
    extends $NotifierProvider<AiConfig, AiConfigState> {
  /// AI 配置：provider、LLM API key 与 base url。
  ///
  /// 两种接入方式均为 OpenAI 兼容协议（/chat/completions + Bearer）：
  /// 配置了 key 后，AI 助手切换为真实 LLM 调用；未配置则使用本地规则引擎。
  AiConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiConfigHash();

  @$internal
  @override
  AiConfig create() => AiConfig();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiConfigState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiConfigState>(value),
    );
  }
}

String _$aiConfigHash() => r'40176f60d42fa6073786fba565b9664c33405ed6';

/// AI 配置：provider、LLM API key 与 base url。
///
/// 两种接入方式均为 OpenAI 兼容协议（/chat/completions + Bearer）：
/// 配置了 key 后，AI 助手切换为真实 LLM 调用；未配置则使用本地规则引擎。

abstract class _$AiConfig extends $Notifier<AiConfigState> {
  AiConfigState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiConfigState, AiConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiConfigState, AiConfigState>,
              AiConfigState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
