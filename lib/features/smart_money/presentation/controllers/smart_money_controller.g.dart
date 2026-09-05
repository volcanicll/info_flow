// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_money_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SmartMoney)
final smartMoneyProvider = SmartMoneyProvider._();

final class SmartMoneyProvider
    extends $NotifierProvider<SmartMoney, SmartMoneyState> {
  SmartMoneyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartMoneyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartMoneyHash();

  @$internal
  @override
  SmartMoney create() => SmartMoney();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartMoneyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartMoneyState>(value),
    );
  }
}

String _$smartMoneyHash() => r'938492e6e2c333500f710c0fee3fda76902b9282';

abstract class _$SmartMoney extends $Notifier<SmartMoneyState> {
  SmartMoneyState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SmartMoneyState, SmartMoneyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SmartMoneyState, SmartMoneyState>,
              SmartMoneyState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
