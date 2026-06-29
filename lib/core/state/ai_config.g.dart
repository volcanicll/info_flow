// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiConfigHash() => r'ebcd939153910f480da9e6e27fd895fb38e88adb';

/// AI 配置：LLM API key 与 base url。
///
/// 配置了 key 后，AI 助手切换为真实 LLM 调用（OpenAI 兼容接口）；
/// 未配置则使用本地规则引擎。本设计只预留入口 + 持久化，
/// 真实 LLM 调用在 ai_chat 模块实现。
///
/// Copied from [AiConfig].
@ProviderFor(AiConfig)
final aiConfigProvider = NotifierProvider<AiConfig, AiConfigState>.internal(
  AiConfig.new,
  name: r'aiConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AiConfig = Notifier<AiConfigState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
