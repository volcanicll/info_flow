// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticker_resolver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tickerDictionary)
final tickerDictionaryProvider = TickerDictionaryProvider._();

final class TickerDictionaryProvider
    extends
        $FunctionalProvider<
          TickerDictionary,
          TickerDictionary,
          TickerDictionary
        >
    with $Provider<TickerDictionary> {
  TickerDictionaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tickerDictionaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tickerDictionaryHash();

  @$internal
  @override
  $ProviderElement<TickerDictionary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TickerDictionary create(Ref ref) {
    return tickerDictionary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TickerDictionary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TickerDictionary>(value),
    );
  }
}

String _$tickerDictionaryHash() => r'8dce374f0272b4eb793141d267e2ec656e1044c8';
