// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoinDetail)
final coinDetailProvider = CoinDetailFamily._();

final class CoinDetailProvider
    extends $NotifierProvider<CoinDetail, CoinDetailState> {
  CoinDetailProvider._({
    required CoinDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'coinDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coinDetailHash();

  @override
  String toString() {
    return r'coinDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CoinDetail create() => CoinDetail();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoinDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoinDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CoinDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coinDetailHash() => r'0ab07ef8f1f1f18cb62c110ad08188d06f301f9f';

final class CoinDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          CoinDetail,
          CoinDetailState,
          CoinDetailState,
          CoinDetailState,
          String
        > {
  CoinDetailFamily._()
    : super(
        retry: null,
        name: r'coinDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CoinDetailProvider call(String symbol) =>
      CoinDetailProvider._(argument: symbol, from: this);

  @override
  String toString() => r'coinDetailProvider';
}

abstract class _$CoinDetail extends $Notifier<CoinDetailState> {
  late final _$args = ref.$arg as String;
  String get symbol => _$args;

  CoinDetailState build(String symbol);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CoinDetailState, CoinDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoinDetailState, CoinDetailState>,
              CoinDetailState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
