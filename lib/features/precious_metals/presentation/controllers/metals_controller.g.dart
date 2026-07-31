// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metals_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Metals)
final metalsProvider = MetalsProvider._();

final class MetalsProvider extends $NotifierProvider<Metals, MetalsState> {
  MetalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metalsHash();

  @$internal
  @override
  Metals create() => Metals();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetalsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetalsState>(value),
    );
  }
}

String _$metalsHash() => r'597268f9ba85c7a781367a215e3d3d87ba54883c';

abstract class _$Metals extends $Notifier<MetalsState> {
  MetalsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MetalsState, MetalsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MetalsState, MetalsState>,
              MetalsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
