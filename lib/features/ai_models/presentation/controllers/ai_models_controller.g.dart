// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_models_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AiModels)
final aiModelsProvider = AiModelsProvider._();

final class AiModelsProvider
    extends $NotifierProvider<AiModels, AiModelsState> {
  AiModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiModelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiModelsHash();

  @$internal
  @override
  AiModels create() => AiModels();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiModelsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiModelsState>(value),
    );
  }
}

String _$aiModelsHash() => r'7a2209e088cd89384b88342bad62e789268d87fa';

abstract class _$AiModels extends $Notifier<AiModelsState> {
  AiModelsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiModelsState, AiModelsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiModelsState, AiModelsState>,
              AiModelsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
