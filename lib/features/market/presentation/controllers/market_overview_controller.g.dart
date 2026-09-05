// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_overview_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MarketOverview)
final marketOverviewProvider = MarketOverviewProvider._();

final class MarketOverviewProvider
    extends $NotifierProvider<MarketOverview, MarketOverviewState> {
  MarketOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketOverviewHash();

  @$internal
  @override
  MarketOverview create() => MarketOverview();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketOverviewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketOverviewState>(value),
    );
  }
}

String _$marketOverviewHash() => r'7cda4dc83b68fe9caff409108b003d2198103d1c';

abstract class _$MarketOverview extends $Notifier<MarketOverviewState> {
  MarketOverviewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MarketOverviewState, MarketOverviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MarketOverviewState, MarketOverviewState>,
              MarketOverviewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
