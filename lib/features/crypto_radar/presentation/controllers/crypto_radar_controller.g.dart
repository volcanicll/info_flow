// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crypto_radar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CryptoRadar)
final cryptoRadarProvider = CryptoRadarProvider._();

final class CryptoRadarProvider
    extends $NotifierProvider<CryptoRadar, CryptoRadarState> {
  CryptoRadarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cryptoRadarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cryptoRadarHash();

  @$internal
  @override
  CryptoRadar create() => CryptoRadar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CryptoRadarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CryptoRadarState>(value),
    );
  }
}

String _$cryptoRadarHash() => r'a79e4ca0d80694ff9fcdb0cb3d3aabea28ae2cd4';

abstract class _$CryptoRadar extends $Notifier<CryptoRadarState> {
  CryptoRadarState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CryptoRadarState, CryptoRadarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CryptoRadarState, CryptoRadarState>,
              CryptoRadarState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
